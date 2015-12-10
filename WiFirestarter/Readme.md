# Wi-Fi restarter

## Overview

このアプリは Mac の Wi-Fi を自動的に on/off します。

## Description

このアプリは、NSTask を使って定期的に default route へ ping します。そして、応答時間を監視します。この時、閾値を超えていたら Wi-Fi を自動的に on -> off -> on します。閾値や監視する時間間隔はメニューから選択できます。

また、Mac がスリープしたら、このアプリもスリープするので実際安心。基本的にアプリ起動後、放置してるだけでいいので実際簡単。

現在、mDNSresponder が舞い戻ってきて、このようなアプリは必要なくなったので公開します。

なお、default route も iface も全部 NSTask を使ったフロントエンドです。

## Requirement

OS X Yosemite or later

## Usage

### Interval ICMP request

メニューから Wi-Fi 監視の時間間隔を選択できます。

- 300 sec (default value)
- 120 sec
- 20 sec
- No repeat

### Threshold ICMP request

メニューから応答時間の閾値を選択できます。

- 2000 ms (default value)
- 1500 ms
- 1000 ms

### ICMP request now

Wi-Fi 監視を手動で実行します。

### Turn Wi-Fi Off/On

Wi-Fi をすぐさま on -> off -> on します。System Preferences を開かなくていいので実際簡単。

### for AppleSeed users

Wi-Fi に問題が起きたら、Wi-Fi を再起動せずデバッグ用のプログラムが起動します。AppleSeed 利用者向けオプション。

## License

Copyright (c) 2015 Tomokatsu Kumata

This software is released under the MIT License, Please see [MIT](https://opensource.org/licenses/MIT)

## Author

[tkumata](https://github.com/tkumata)