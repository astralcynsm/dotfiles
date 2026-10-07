use anyhow::{Context, Result};
use chrono::Local;
use crossbeam_channel::{bounded, select};
use notify::{Config, RecommendedWatcher, RecursiveMode, Watcher};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs::{self, File};
use std::io::{Seek, SeekFrom, Write};
use std::path::{Path, PathBuf};
use std::time::Duration;

// 设备标识
const DEVICE_KEY: &str = "endeavour_os_main";
// 临时状态文件路径
const STATUS_FILE: &str = "/tmp/rime_status.json";

#[derive(Debug, Serialize, Deserialize)]
struct HistoryData {
    per_day: HashMap<String, u64>,
    last_offsets: HashMap<String, u64>,
    #[serde(default)]
    updated_at: String,
}

#[derive(Debug, Serialize)]
struct HyprPanelOutput {
    text: String,
    tooltip: String,
    class: String,
    alt: String,
}

fn main() -> Result<()> {
    let home = std::env::var("HOME").context("Could not find HOME")?;
    let base_path = PathBuf::from(&home).join(".local/share/fcitx5/rime/py_wordscounter");
    let csv_path = base_path.join("words_input.csv");
    let json_path = base_path.join("words_count_history.json");

    // 1. 初始化数据
    let mut history = load_or_init_history(&json_path)?;

    // 2. 启动时先执行一次
    if let Err(e) = process_and_write(&csv_path, &mut history, &json_path) {
        eprintln!("Initial process error: {}", e);
    }

    // 3. 设置文件监听
    let (tx, rx) = bounded(10);
    let mut watcher = RecommendedWatcher::new(
        move |res| {
            let _ = tx.send(res);
        },
        Config::default(),
    )?;

    if let Some(parent) = csv_path.parent() {
        watcher.watch(parent, RecursiveMode::NonRecursive)?;
        println!("Rime Counter Daemon started. Watching {:?}", parent);
    }

    // 4. 事件循环
    loop {
        select! {
            recv(rx) -> res => {
                match res {
                    Ok(Ok(event)) => {
                        if event.paths.iter().any(|p| p.ends_with("words_input.csv")) {
                            // 极短的防抖
                            std::thread::sleep(Duration::from_millis(10));
                            if let Err(e) = process_and_write(&csv_path, &mut history, &json_path) {
                                eprintln!("Processing error: {}", e);
                            }
                        }
                    },
                    Ok(Err(e)) => eprintln!("Watch error: {}", e),
                    Err(_) => break,
                }
            }
        }
    }

    Ok(())
}

fn load_or_init_history(path: &Path) -> Result<HistoryData> {
    if path.exists() {
        let file = File::open(path)?;
        let data: HistoryData = serde_json::from_reader(file).unwrap_or_else(|_| HistoryData {
            per_day: HashMap::new(),
            last_offsets: HashMap::new(),
            updated_at: String::new(),
        });
        Ok(data)
    } else {
        Ok(HistoryData {
            per_day: HashMap::new(),
            last_offsets: HashMap::new(),
            updated_at: String::new(),
        })
    }
}

fn process_and_write(csv_path: &Path, history: &mut HistoryData, json_path: &Path) -> Result<()> {
    if !csv_path.exists() {
        return Ok(());
    }

    let mut file = File::open(csv_path)?;
    let metadata = file.metadata()?;
    let current_size = metadata.len();
    let last_offset = *history.last_offsets.get(DEVICE_KEY).unwrap_or(&0);
    let start_offset = if current_size < last_offset { 0 } else { last_offset };

    if start_offset < current_size {
        file.seek(SeekFrom::Start(start_offset))?;
        let mut rdr = csv::ReaderBuilder::new()
            .has_headers(false)
            .from_reader(file);

        for result in rdr.records() {
            if let Ok(record) = result {
                if record.len() >= 6 {
                    let timestamp_str = &record[1];
                    let count_str = &record[5];
                    if let Ok(count) = count_str.parse::<u64>() {
                        if timestamp_str.len() >= 10 {
                            let date_key = String::from(&timestamp_str[0..10]);
                            *history.per_day.entry(date_key).or_insert(0) += count;
                        }
                    }
                }
            }
        }
        
        history.last_offsets.insert(DEVICE_KEY.to_string(), current_size);
        history.updated_at = Local::now().format("%Y-%m-%d %H:%M:%S").to_string();
        
        let write_file = File::create(json_path)?;
        serde_json::to_writer_pretty(write_file, &history)?;
    }

    let output = generate_output(history);
    
    // 原子写入 /tmp
    let tmp_path = format!("{}.tmp", STATUS_FILE);
    let mut tmp_file = File::create(&tmp_path)?;
    tmp_file.write_all(serde_json::to_string(&output)?.as_bytes())?;
    fs::rename(&tmp_path, STATUS_FILE)?;

    Ok(())
}

fn generate_output(history: &HistoryData) -> HyprPanelOutput {
    let now = Local::now();
    let today_str = now.format("%Y-%m-%d").to_string();
    let today_count = *history.per_day.get(&today_str).unwrap_or(&0);

    let month_str = now.format("%Y-%m").to_string();
    let month_count: u64 = history.per_day.iter()
        .filter(|(k, _)| k.starts_with(&month_str))
        .map(|(_, v)| v)
        .sum();

    let heatmap = generate_ascii_heatmap(&history.per_day, 21);

    HyprPanelOutput {
        text: format!("{} 字", today_count),
        tooltip: format!(
            "<span weight='bold' color='#a6e3a1'>Today:</span> {}\n<span weight='bold' color='#89b4fa'>Month:</span> {}\n\n<span size='small'>{}</span>", 
            today_count, month_count, heatmap
        ),
        class: if today_count > 0 { "active".to_string() } else { "idle".to_string() },
        alt: "ime".to_string(),
    }
}

fn generate_ascii_heatmap(data: &HashMap<String, u64>, days: i64) -> String {
    let now = Local::now().date_naive();
    let start_date = now - chrono::Duration::try_days(days - 1).unwrap();
    let mut max_val = 1;
    for i in 0..days {
        let d = start_date + chrono::Duration::try_days(i).unwrap();
        let k = d.format("%Y-%m-%d").to_string();
        if let Some(&v) = data.get(&k) {
            if v > max_val { max_val = v; }
        }
    }

    let mut line = String::new();
    for i in 0..days {
        let d = start_date + chrono::Duration::try_days(i).unwrap();
        let k = d.format("%Y-%m-%d").to_string();
        let val = *data.get(&k).unwrap_or(&0);
        let level = if val == 0 { 0 } else if val < max_val / 4 { 1 } else if val < max_val / 2 { 2 } else if val < max_val * 3 / 4 { 3 } else { 4 };
        let char = match level { 0 => "○", 1 => "░", 2 => "▒", 3 => "▓", 4 => "█", _ => "?" };
        line.push_str(char);
    }
    
    let mut detail = String::from("\nLast 7 days:\n");
    for i in 0..7 {
        let d = now - chrono::Duration::try_days(6 - i).unwrap();
        let k = d.format("%Y-%m-%d").to_string();
        let val = *data.get(&k).unwrap_or(&0);
        detail.push_str(&format!("{}: {:<5} \n", d.format("%m-%d"), val));
    }
    format!("{}{}", line, detail)
}
