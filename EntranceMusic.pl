#!/usr/local/bin/perl

my %PLAYLIST = (
    "70:14:A6:38:1A:44" => "\/home\/pi\/EntranceMusic\/music\/skyfall.mp3",
);


my %folks = ();
my $fiveSecTimer = time;
    
open(PS_F, "sudo airodump-ng --output-format csv wlan0mon 2>&1 |");

while (<PS_F>) {
    
    $hex = "[0123456789ABCDEF][0123456789ABCDEF]";
    $match = "(?<=  )$hex\:$hex\:$hex\:$hex\:$hex\:$hex(?= )";
    my($macID) = ($_ =~ m/($match)/);
    
    if ($macID) {

        if (exists $folks{$macID}) {
            $folks{$macID}{last_seen} = time;
        } else {
            $folks{$macID}{just_arrived} = 1;
            $folks{$macID}{first_seen} = time;
            $folks{$macID}{last_seen} = time;
            print "$macID has just arrived.\n";
        }
    }
    
    # 60sec timer
    if ((time - $fiveSecTimer) > (60)) {

        $fiveSecTimer = time;
        
        # remove folks who has left
        while (($key, $value) = each %folks) {
            if ((time - $folks{$key}{last_seen}) > (5*60)) {
                delete $folks{$key};
                print "$key has left the building.\n";
            }
        }
        
        # folks who are here for a while does not need wellcome anymore
        while (($key, $value) = each %folks) {
            if ($folks{$key}{just_arrived}) {
                if ((time - $folks{$key}{first_seen}) > (5*60)) {
                    $folks{$key}{just_arrived} = 0;
                    print "$key does not need wellcome anymore.\n";
                }
            }
        }
    }

    my $isDoorOpen = `sudo python CheckDoor.py`;
    if ($isDoorOpen =~ /OPEN/) {
        
        while (($key, $value) = each %folks) {
            if ($folks{$key}{just_arrived}) {
                
                $folks{$key}{just_arrived} = 0;
                if (exists $PLAYLIST{$key}) {
                    print "$key is being greeted.\n";
                    $CMD = "omxplayer $PLAYLIST{$key} &";
                    print "$CMD\n";
                    system("$CMD");
                } else {
                    print "$key will not be greeted.\n";
                }
            }
        }
       
    }
}
    
close(PS_F);
