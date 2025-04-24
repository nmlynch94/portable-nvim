#!/bin/bash
sudo su "${USERNAME}" nvm install 20

start_xrdp_services() {
  # Preventing xrdp startup failure
  rm -rf /var/run/xrdp-sesman.pid
  rm -rf /var/run/xrdp.pid
  rm -rf /var/run/xrdp/xrdp-sesman.pid
  rm -rf /var/run/xrdp/xrdp.pid

  # Use exec ... to forward SIGNAL to child processes
  xrdp-sesman && exec xrdp -n
}

stop_xrdp_services() {
  xrdp --kill
  xrdp-sesman --kill
  exit 0
}

echo -e "starting xrdp services...\n"

trap "stop_xrdp_services" SIGTERM SIGHUP SIGINT EXIT
wait
start_xrdp_services
