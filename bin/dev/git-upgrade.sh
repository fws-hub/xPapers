#!/bin/bash
git pull
perl -Ilib bin/apply-sql-patches.pl 0 1.0
sudo perl bin/start
