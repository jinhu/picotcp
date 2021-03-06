#!/bin/bash

sh ./test/vde_sock_start_user.sh
sleep 2
ulimit -c unlimited


echo "PING TEST"
(./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.8:255.255.0.0:) &
./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.9:255.255.0.0: -a ping:10.40.0.8: || exit 1
killall picoapp.elf

echo "TCP TEST"
(./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.8:255.255.0.0: -a tcpbench:r:6667:) &
time (./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.9:255.255.0.0: -a tcpbench:t:10.40.0.8:6667: || exit 1)
killall picoapp.elf

echo "UDP TEST"
(./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.8:255.255.0.0: -a udpecho:10.40.0.8:6667) &
./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.9:255.255.0.0: -a udpclient:10.40.0.8:6667:6667:1400:100:10 || exit 1
wait || exit 1
wait

echo "NAT TCP TEST"
(./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.10:255.255.0.0: --vde pic1:/tmp/pic1.ctl:10.50.0.10:255.255.0.0: -a natbox:10.50.0.10) &
sleep 2
(./build/test/picoapp.elf --vde pic0:/tmp/pic1.ctl:10.50.0.8:255.255.0.0: -a tcpbench:r:6667) &
sleep 2
./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.9:255.255.0.0:10.40.0.10: -a tcpbench:t:10.50.0.8:6667: || exit 1
killall picoapp.elf

echo "NAT UDP TEST"
(./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.10:255.255.0.0: --vde pic1:/tmp/pic1.ctl:10.50.0.10:255.255.0.0: -a natbox:10.50.0.10) &
(./build/test/picoapp.elf --vde pic0:/tmp/pic1.ctl:10.50.0.8:255.255.0.0: -a udpecho:10.50.0.8:6667) &
./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.9:255.255.0.0:10.40.0.10: -a udpclient:10.50.0.8:6667:6667:1400:100:10 || exit 1
#sometimes udpecho finishes before reaching wait %2
#wait %2

killall picoapp.elf

echo "MULTICAST TEST"
(./build/test/picoapp.elf --vde pic1:/tmp/pic0.ctl:10.40.0.3:255.255.0.0: -a mcastreceive:10.40.0.3:224.7.7.7:6667:6667) &
(./build/test/picoapp.elf --vde pic2:/tmp/pic0.ctl:10.40.0.4:255.255.0.0: -a mcastreceive:10.40.0.4:224.7.7.7:6667:6667) &
(./build/test/picoapp.elf --vde pic3:/tmp/pic0.ctl:10.40.0.5:255.255.0.0: -a mcastreceive:10.40.0.5:224.7.7.7:6667:6667) &
sleep 2
./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.2:255.255.0.0: -a mcastsend:10.40.0.2:224.7.7.7:6667:6667 || exit 1
(wait && wait && wait) || exit 1

killall picoapp.elf

echo "DHCP TEST"
(./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.1:255.255.0.0: -a dhcpserver:pic0:10.40.0.1:255.255.255.0:64:128:) &
./build/test/picoapp.elf --barevde pic0:/tmp/pic0.ctl: -a dhcpclient:pic0 || exit 1
killall picoapp.elf

echo "DHCP DUAL TEST"
(./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.2:255.255.0.0: -a dhcpserver:pic0:10.40.0.2:255.255.255.0:64:128:) &
(./build/test/picoapp.elf --vde pic1:/tmp/pic1.ctl:10.50.0.2:255.255.0.0: -a dhcpserver:pic1:10.50.0.2:255.255.255.0:64:128:) &
./build/test/picoapp.elf --barevde pic0:/tmp/pic0.ctl: --barevde pic1:/tmp/pic1.ctl: -a dhcpclient:pic0:pic1 || exit 1
killall picoapp.elf

echo "SUCCESS!" && exit 0
