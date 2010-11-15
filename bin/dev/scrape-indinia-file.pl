while (<STDIN>) {

    if (m!href="/journal/\d+">(.+?)</a>!) {
        print "$1\n";
    }
}
