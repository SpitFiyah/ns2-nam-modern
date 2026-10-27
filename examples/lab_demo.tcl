# NS-2 / NAM Demonstration Script
# Simple topology: 4 Nodes with TCP FTP and UDP CBR flows

set ns [new Simulator]

# Set colors for data flows (visible in NAM)
$ns color 1 Blue
$ns color 2 Red

# Open NAM trace file
set nf [open out.nam w]
$ns namtrace-all $nf

# Define 'finish' procedure
proc finish {} {
    global ns nf
    $ns flush-trace
    close $nf
    puts "=========================================================="
    puts " Simulation finished successfully."
    puts " Launching NAM animation (out.nam)..."
    puts "=========================================================="
    exec nam out.nam &
    exit 0
}

# Create nodes
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]

# Label nodes for NAM
$n0 label "TCP Source"
$n1 label "UDP Source"
$n2 label "Router / Gateway"
$n3 label "Receiver / Sink"

# Create links between nodes (Bandwidth, Delay, Queue Type)
$ns duplex-link $n0 $n2 2Mb 10ms DropTail
$ns duplex-link $n1 $n2 2Mb 10ms DropTail
$ns duplex-link $n2 $n3 1.7Mb 20ms DropTail

# Set queue limit on bottleneck link
$ns queue-limit $n2 $n3 10

# Position layout for NAM visualization
$ns duplex-link-op $n0 $n2 orient right-down
$ns duplex-link-op $n1 $n2 orient right-up
$ns duplex-link-op $n2 $n3 orient right
$ns duplex-link-op $n2 $n3 queuePos 0.5

# Setup TCP Connection
set tcp [new Agent/TCP]
$tcp set class_ 1
$ns attach-agent $n0 $tcp
set sink [new Agent/TCPSink]
$ns attach-agent $n3 $sink
$ns connect $tcp $sink
$tcp set fid_ 1

# Setup FTP application over TCP
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ftp set type_ FTP

# Setup UDP Connection
set udp [new Agent/UDP]
$ns attach-agent $n1 $udp
set null [new Agent/Null]
$ns attach-agent $n3 $null
$ns connect $udp $null
$udp set fid_ 2

# Setup CBR traffic application over UDP
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set rate_ 1mb
$cbr set random_ false

# Event Schedule
$ns at 0.1 "$cbr start"
$ns at 1.0 "$ftp start"
$ns at 4.0 "$ftp stop"
$ns at 4.5 "$cbr stop"
$ns at 5.0 "finish"

# Run the simulation
$ns run
