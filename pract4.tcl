# Define options
set opt(chan) Channel/WirelessChannel ;#Channel type
set opt(prop) Propagation/TwoRayGround ;# radio-propagation model
set opt(netif) Phy/WirelessPhy ;# network interface type
set opt(mac) Mac/Gprs;# MAC type
set opt(ifq) Queue/DropTail/PriQueue ;# interface queue type
set opt(ll) LL ;# Link layer type
set opt(rl) RLC
set opt(ant) Antenna/OmniAntenna ;# antenna model
set opt(ifqlen) 5000 ;# max paket in ifq
set opt(adhoc) NOAH ;# routing protool
set opt(x) 70 ;# xoordinate of topology
set opt(y) 70 ;# yoordinate of topology
set opt(seed) 0.0 ;# seed for random num gen.
set opt(tr) "/tmp/riha/sim1.tr"
set opt(start) 0.0
set opt(stop) 80 ;# time to stop simulation
set num_bs_nodes 1
set opt(nn) 5 ;# number of mobilenodes
set opt(rate) 15k
Mac/Gprs set gprs_slots_per_frame_ 7
Mac/Gprs set slot_packet_len_ 53
Mac/Gprs set max_num_ms_ 15
Mac/Gprs set max_num_freq_ 2
Mac/Gprs set gprs_ 1
Mac/Gprs set rlc_error_ 0
Mac/Gprs set error_rate_ 1000
Mac/Gprs set verbose_ 0
LL set acked_ 0
LL set llfraged_ 1
LL set llfragsz_ 1520
LL set llverbose_ 0
RLC set acked_ 0
RLC set rlcfraged_ 1
RLC set rlcfragsz_ 50
RLC set rlcverbose_ 0
#remove unneessary paket headers, else eah pkt takes 2kb!
remove-packet-header LDP MPLS Snoop
remove-packet-header Ping TFRC TFRC_ACK
remove-packet-header Diffusion RAP IMEP
remove-packet-header AODV SR TORA IPinIP
remove-packet-header MIP HttpInval
remove-packet-header MFTP SRMEXT SRM aSRM
remove-packet-header mcastCtrl CtrMcast IVS
remove-paket-header Resv UMP Flags
#Create simulator instane
set ns_ [new Simulator]
# set up for hierarchical routing
$ns_ node-config -addressType hierarchical
AddrParams set domain_num_ 1 ;# number of domains 
lappend cluster_num 1 ;# number ofclusters in each domain
AddrParams set cluster_num_ $cluster_num
lappend eilastlevel 6 ;# number of nodes in eachcluster
AddrParams set nodes_num_ $eilastlevel ;# of each domain
set tracefd [open $opt(tr) w]
$ns_ trace-all $tracefd
# Create topography object
set topo [new Topography]
# define topology
$topo load_flatgrid $opt(x) $opt(y)
#create God 
create-god $opt(nn)
set chan1 [new $opt(chan)]
#configure for base-station node
$ns_ node-config -adhocRouting $opt(adhocRouting) \
-llType $opt(ll) \
-rlcType $opt(rlc) \
-macType $opt(mac) \
-ifqType $opt(ifq) \
-ifqLen $opt(ifqlen) \
-antType $opt(ant) \
-propType $opt(prop) \
-phyType $opt(netif)\
-topoInstance $topo \
-wiredRouting ON \
-agentTrace ON \
-routerTrace OFF \
-macTrace OFF \
-movementTrace OFF \
-channel $chan1
#create base-station node
set temp {1.0.0 1.0.1 1.0.2 1.0.3 1.0.4 1.0.5 1.0.6 1.0.7 }
# hier address to be used for wireless domain
set BS(0) [$ns_ node [lindex $temp 0]]
$BS(0) random-motion 0 ;# disable random motion
#provide some co-ord (fixed) to base station node
$BS(0) set X_ 1.0
$BS(0) set Y_ 2.0
$BS(0) set Z_ 0.0
#configure for mobilenodes
$ns_ node-config -wiredRouting OFF
#create mobilenodes in the same domain as BS(0)
for {set j 0} {$j < $opt(nn)} {incr j} {
set node_($j) [ $ns_ node [lindex $temp [expr $j+1]]]
$node_($j) base-station [AddrParams addr2id [$BS(0) node-addr]]
}
for {set j 0} {$j < $opt(nn)} {incr j} {
set s($j) [new Agent/TCP]
$ns_ attach-agent $node_($j) $s($j)
$s($j) set packetSize_ 1500
set null($j) [new Agent/TCPSink]
$ns_ attach-agent $BS(0) $null($j)
$null($j) set packetSize_ 30
$ns_connect $s($j) $null($j)
set exp($j) [new Application/Traffic/Exponential]
$exp($j) set burst_time_ 500ms
$exp($j) set idle_time_ 500ms
$exp($j) set rate_ $opt(rate)
$exp($j) attach-agent $s($j)
$ns_ at $opt(start) "$exp($j) start"
}
# Tell all nodes when the simulation ends
for {set i } {$i < $opt(nn) } {incr i} {
$ns_ at $opt(stop).0 "$node_($i) reset";
}
$ns_ at $opt(stop).0 "$BS(0) reset";
$ns_ at $opt(stop).0002 "puts \" \" ; $ns_ halt"
$ns_ at $opt(stop).0001 "stop"
proc stop {} {
global ns_ tracefd
$ns_ flush-trace
lose $tracefd
}
#puts "Starting Simulation..."
$ns_ run


