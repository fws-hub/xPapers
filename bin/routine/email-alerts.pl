$|=1;
use xPapers::Alert;
use xPapers::Utils::System;

unique(1,'email-alerts.pl');

while(1) {
    xPapers::AlertManager->process(20);
    sleep(30);
}

1;
