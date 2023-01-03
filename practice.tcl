set ns [ new Simulator ]

set tf [ open practice.tr w ]
$ns trace-all $tf

set nf [ open practice.nam w ]
$ns namtrace-all $nf

set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]
set n6 [$ns node]

proc finish { } {
	global ns tf nf 
	$ns flush-trace
	exec nam practice.nam &
	close $tf
	close $nf
	exit 0
}

$n0 label "Source/udp0"
$n1 label "Source/udp1"
$n2 label "Source/udp2"
$n3 label "Source/upd3"
$n4 label "Source/upd4"
$n5 label "Router"
$n6 label "Destination/null"

$ns color 1 blue
$ns color 2 red

$ns duplex-link $n0 $n5 100Mb 300ms DropTail
$ns duplex-link $n1 $n5 100Mb 300ms DropTail
$ns duplex-link $n2 $n5 100Mb 300ms DropTail
$ns duplex-link $n3 $n5 100Mb 300ms DropTail
$ns duplex-link $n4 $n5 100Mb 300ms DropTail
$ns duplex-link $n5 $n6 1Mb 300ms DropTail

$ns set queue-limit $n0 $n5 50
$ns set queue-limit $n1 $n5 50
$ns set queue-limit $n2 $n5 50
$ns set queue-limit $n3 $n5 50
$ns set queue-limit $n4 $n5 50
$ns set queue-limit $n5 $n6 5

set udp0 [new Agent/UDP]
$ns attach-agent $n0 $udp0
set cbr0 [new Application/Traffic/CBR]
$cbr0 set packetSize_ 500
$cbr0 set interval_ 0.005
$cbr0 attach-agent $udp0

set udp1 [new Agent/UDP]
$ns attach-agent $n1 $udp1
set cbr1 [new Application/Traffic/CBR]
$cbr1 set packetSize_ 500
$cbr1 set interval_ 0.006
$cbr1 attach-agent $udp1

set udp2 [new Agent/UDP]
$ns attach-agent $n2 $udp2
set cbr2 [new Application/Traffic/CBR]
$cbr2 set packetSize_ 500
$cbr2 set interval_ 0.007
$cbr2 attach-agent $udp2

set udp3 [new Agent/UDP]
$ns attach-agent $n3 $udp3
set cbr3 [new Application/Traffic/CBR]
$cbr3 set packetSize_ 500
$cbr3 set interval_ 0.008
$cbr3 attach-agent $udp3

set udp4 [new Agent/UDP]
$ns attach-agent $n4 $udp4
set cbr4 [new Application/Traffic/CBR]
$cbr4 set packetSize_ 500
$cbr4 set interval_ 0.009
$cbr4 attach-agent $udp4

set null6 [new Agent/Null]
$ns attach-agent $n6 $null6
$ns connect $udp0 $null6
$ns connect $udp1 $null6
$ns connect $udp2 $null6
$ns connect $udp3 $null6
$ns connect $udp4 $null6

$ns at 0.2 "$cbr0 start"
$ns at 0.4 "$cbr1 start"
$ns at 0.6 "$cbr2 start"
$ns at 0.8 "$cbr3 start"
$ns at 1.0 "$cbr4 start"

$ns at 4.5 "$cbr0 stop"
$ns at 4.6 "$cbr1 stop"
$ns at 4.7 "$cbr2 stop"
$ns at 4.8 "$cbr3 stop"
$ns at 4.9 "$cbr4 stop"

$ns at 10.0 "finish"
$ns run
