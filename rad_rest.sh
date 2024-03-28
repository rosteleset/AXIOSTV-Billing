#!/bin/bash
/usr/bin/killall -9 radiusd
echo Radius stopped
/usr/sbin/radiusd
echo Radius started
