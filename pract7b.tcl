# General Parameters
set opt(title) zero ;
set opt(stop) 100 ;# Stop time.
set opt(ecn) 0 ;
# Topology
set opt(type) gsm ;#type of link:
set opt(secondDelay) 55 ;# average delay of access links in ms
# AQM parameters
set opt(minth) 30 ;
set opt(maxth) 0 ;
set opt(adaptive) 1 ;# 1 for Adaptive RED, 0 for plain RED
# Traffic generation.
set opt(flows) 0 ;# number of long-lived TCP flows
set opt(window) 30 ;# window for long-lived traffic
set opt(web) 2 ;# number of web sessions
# Plotting statistics.
set opt(quiet) 0 ;# popup anything
set opt(wrap) 100 ;# wrap plots
set opt(srcTrace) is ;# where to plot traffic
set opt(dstTrace) bs2 ;# where to plot traffic
set opt(gsmbuf) 10 ; # buffer size for gsm
#default downlink bandwidth in bps
set bwDL(gsm) 9600
#default uplink bandwidth in bps
set bwUL(gsm) 9600
#default downlink propagation delay in seconds
set propDL(gsm) .500
#default uplink propagation delay in seconds
set propUL(gsm) .500
#default buffer size in packets
set buf(gsm) 10
set ns [new Simulator]
set tf [open out.tr w]
$ns trace-all $tf
set nodes(is) [$ns node]
set nodes(ms) [$ns node]
set nodes(bs1) [$ns node]
set nodes(bs2) [$ns node]
set nodes(lp) [$ns node]
proc cell_topo {} {
global ns nodes
$ns duplex-link $nodes(lp) $nodes(bs1) 3Mbps 10ms DropTail
$ns duplex-link $nodes(bs1) $nodes(ms) 1 1 RED
$ns duplex-link $nodes(ms) $nodes(bs2) 1 1 RED
$ns duplex-link $nodes(bs2) $nodes(is) 3Mbps 50ms DropTail
puts "Cell Topology"
}

 proc set_link_params {t} {
 global ns nodes bwUL bwDL propUL propDL buf
 $ns bandwidth $nodes(bs1) $nodes(ms) $bwDL($t) simplex
 $ns bandwidth $nodes(ms) $nodes(bs1) $bwUL($t) simplex
 $ns bandwidth $nodes(bs2) $nodes(ms) $bwDL($t) simplex
 $ns bandwidth $nodes(ms) $nodes(bs2) $bwUL($t) simplex
 $ns delay $nodes(bs1) $nodes(ms) $propDL($t) simplex
 $ns delay $nodes(ms) $nodes(bs1) $propDL($t) simplex
 $ns delay $nodes(bs2) $nodes(ms) $propDL($t) simplex
 $ns delay $nodes(ms) $nodes(bs2) $propDL($t) simplex
 $ns queue-limit $nodes(bs1) $nodes(ms) $buf($t)
 $ns queue-limit $nodes(ms) $nodes(bs1) $buf($t)
 $ns queue-limit $nodes(bs2) $nodes(ms) $buf($t)
 $ns queue-limit $nodes(ms) $nodes(bs2) $buf($t)
}
# RED and TCP parameters
Queue/RED set summarystats_ true
Queue/DropTail set summarystats_ true
Queue/RED set adaptive_ $opt(adaptive)
Queue/RED set q_weight_ 0.0
Queue/RED set thresh_ $opt(minth)
Queue/RED set maxthresh_ $opt(maxth)
Queue/DropTail set shrink_drops_ true
Agent/TCP set ecn_ $opt(ecn)
Agent/TCP set window_ $opt(window)
DelayLink set avoidReordering_ true
source web.tcl
#Create topology
switch $opt(type) {
gsm -
gprs -
umts {cell_topo}
}
 set_link_params $opt(type)
 $ns insert-delayer $nodes(ms) $nodes(bs1) [new Delayer]
 $ns insert-delayer $nodes(bs1) $nodes(ms) [new Delayer]
 $ns insert-delayer $nodes(ms) $nodes(bs2) [new Delayer]
 $ns insert-delayer $nodes(bs2) $nodes(ms) [new Delayer]
# Set up forward TCP connection
if {$opt(flows) == 0} {
set tcp1 [$ns create-connection TCP/Sack1 $nodes(is) TCPSink/Sack1 $nodes(lp) 0]
set ftp1 [[set tcp1] attach-app FTP]
$ns at 0.8 "[set ftp1] start"
}
if {$opt(flows) > 0} {
 set tcp1 [$ns create-connection TCP/Sack1 $nodes(is) TCPSink/Sack1 $nodes(lp) 0]
 set ftp1 [[set tcp1] attach-app FTP]
 $tcp1 set window_ 100
 $ns at 0.0 "[set ftp1] start"
 
 $ns at 3.5 "[set ftp1] stop"
 set tcp2 [$ns create-connection TCP/Sack1 $nodes(is) TCPSink/Sack1 $nodes(lp) 0]
 set ftp2 [[set tcp2] attach-app FTP]
 $tcp2 set window_ 3
 $ns at 1.0 "[set ftp2] start"
 $ns at 8.0 "[set ftp2] stop"
}
proc stop {} {
global nodes opt nf
set wrap $opt(wrap)
set sid [$nodes($opt(srcTrace)) id]
set did [$nodes($opt(dstTrace)) id]
if {$opt(srcTrace) == "is"} {
set a "-a out.tr"
} else {
set a "out.tr"
}
set GETRC "../../../bin/getrc"
 set RAW2XG "../../../bin/raw2xg"
 exec $GETRC -s $sid -d $did -f 0 out.tr | \
 $RAW2XG -s 0.01 -m $wrap -r > plot.xgr
 exec $GETRC -s $did -d $sid -f 0 out.tr | \
 $RAW2XG -a -s 0.01 -m $wrap >> plot.xgr
 exec $GETRC -s $sid -d $did -f 1 out.tr | \
 $RAW2XG -s 0.01 -m $wrap -r >> plot.xgr
 exec $GETRC -s $did -d $sid -f 1 out.tr | \
 $RAW2XG -s 0.01 -m $wrap -a >> plot.xgr
exec ./xg2gp.awk plot.xgr
 if {!$opt(quiet)} {
 exec xgraph -bb -tk -nl -m -x time -y packets plot.xgr &
 }
exit 0
}
$ns at $opt(stop) "stop"
$ns run

