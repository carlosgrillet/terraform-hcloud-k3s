#!/usr/bin/env nu
# Dynamically retrieve servers with the control-plane label.
let API = "https://api.hetzner.cloud/v1/servers"
let CFG = "/etc/haproxy/haproxy.d/k8s.cfg"
let TOKEN = "${token}"

http get --headers ["Authorization" $"Bearer ($TOKEN)"] $API | $in.servers |
  each {|server|
    if ($server.labels | default "false" "control-plane" | get control-plane) == "true" {
        $"option ssl-hello-chk\n  server ($server.name) ($server.private_net.0.ip):6443 maxconn 64 check inter 2000 rise 2 fall 5"
    }
  } | str join "\n  " | $"listen k8s\n  mode tcp\n  bind :6443\n  ($in)\n" | save -f $CFG

systemctl reload haproxy