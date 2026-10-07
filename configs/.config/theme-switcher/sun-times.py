#!/usr/bin/env python3
"""
算上海的日出 / 日落时刻。

用法:
    sun-times.py              # 今天
    sun-times.py 2026-12-25   # 指定日期

输出:
    05:47 17:53               # 空格分隔的「日出 日落」，本地时间（UTC+8）

算法：Wikipedia「Sunrise equation」，太阳高度角取 -0.833°
（= 大气折射 34′ + 太阳视半径 16′，这是「日出」的标准定义）。
纯标准库，不依赖 astral / sunwait 等任何外部包。
"""

import math
import sys
from datetime import date, datetime, timedelta, timezone

# 上海人民广场
LAT = 31.2304
LON = 121.4737
TZ = 8  # 北京时间 UTC+8

# 日出/日落的标准太阳高度角
ALT = -0.833

# 地轴倾角
OBLIQUITY = 23.4397


def julian_day(d):
    """date → 当天 00:00 UT 的儒略日。"""
    y, m = d.year, d.month
    if m <= 2:
        y -= 1
        m += 12
    a = y // 100
    b = 2 - a + a // 4
    return (math.floor(365.25 * (y + 4716))
            + math.floor(30.6001 * (m + 1))
            + d.day + b - 1524.5)


def jd_to_local(jd, tz):
    """儒略日 → 指定时区的 datetime。"""
    ts = (jd - 2440587.5) * 86400.0
    return datetime.fromtimestamp(ts, timezone(timedelta(hours=tz)))


def sun_times(day, lat=LAT, lon=LON, tz=TZ):
    """返回 (sunrise, sunset)，都是带时区的 datetime；极昼/极夜返回 (None, None)。"""
    jd = julian_day(day)

    # 平太阳时的天数计数（含经度修正）
    n = jd + 0.5 - 2451545.0 + 0.0008 - lon / 360.0

    # 平近点角
    M = (357.5291 + 0.98560028 * n) % 360.0
    # 中心差
    C = (1.9148 * math.sin(math.radians(M))
         + 0.0200 * math.sin(math.radians(2 * M))
         + 0.0003 * math.sin(math.radians(3 * M)))
    # 黄经
    lam = (M + C + 180.0 + 102.9372) % 360.0

    # 太阳中天
    j_transit = (2451545.0 + n
                 + 0.0053 * math.sin(math.radians(M))
                 - 0.0069 * math.sin(math.radians(2 * lam)))

    # 赤纬
    sin_dec = math.sin(math.radians(lam)) * math.sin(math.radians(OBLIQUITY))
    dec = math.asin(sin_dec)

    # 时角
    cos_omega = ((math.sin(math.radians(ALT))
                  - math.sin(math.radians(lat)) * sin_dec)
                 / (math.cos(math.radians(lat)) * math.cos(dec)))

    if cos_omega > 1 or cos_omega < -1:
        return None, None  # 极夜 / 极昼

    omega = math.degrees(math.acos(cos_omega))

    return (jd_to_local(j_transit - omega / 360.0, tz),
            jd_to_local(j_transit + omega / 360.0, tz))


def main():
    if len(sys.argv) > 1:
        try:
            day = date.fromisoformat(sys.argv[1])
        except ValueError:
            sys.exit(f"日期格式应为 YYYY-MM-DD，给的是 {sys.argv[1]!r}")
    else:
        day = date.today()

    rise, sett = sun_times(day)
    if rise is None:
        sys.exit("该日期在上海没有日出/日落（极昼或极夜，不该发生）")

    print(f"{rise:%H:%M} {sett:%H:%M}")


if __name__ == "__main__":
    main()
