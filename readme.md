# AREDN Channel test setup 20200322
The purpose of these tests are to evaluate performance and behavior of AREDN devices with controlled rf coupling  
See [AREDN CHTEST SETUP 2020322.pdf](./doc/AREDN CHTEST SETUP 2020322.pdf)

## Test sequence
1. Take baseline throughput, maximum 1 way stream between each radio pair
2. Configure radios to operate on experiment defined channels
3. For each test speed and each radio pair start 2 way concurrent iperf tests
4. Record all data to json, plot and analyze

# TODO
* Find a better way to couple radios
    * Existing setup channels too lossy
    * Need to couple both MIMO ports
    * RF chamber+antennas big, annoying, unstable
* Design coupling system for hidden node test
* Design tests for evaluating multiple concurrent MCS behavior

    