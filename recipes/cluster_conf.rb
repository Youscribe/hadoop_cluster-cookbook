#
# Cookbook Name::       hadoop_cluster
# Description::         Configure cluster
# Recipe::              cluster_conf
# Author::              Philip (flip) Kromer - Infochimps, Inc
#
# Copyright 2011, Philip (flip) Kromer - Infochimps, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Configuration files
#
# Find these variables in ../hadoop_cluster/libraries/hadoop_cluster.rb
#

node[:hadoop][:namenode   ][:addr] = discover(:hadoop, :namenode   ).private_ip rescue nil
node[:hadoop][:jobtracker ][:addr] = discover(:hadoop, :jobtracker ).private_ip rescue nil
node[:hadoop][:secondarynn][:addr] = discover(:hadoop, :secondarynn).private_ip rescue nil

%w[ core-site.xml     hdfs-site.xml     mapred-site.xml
    hadoop-env.sh     fairscheduler.xml hadoop-metrics.properties
].each do |conf_file|
  template "#{node[:hadoop][:conf_dir]}/#{conf_file}" do
    owner "root"
    mode "0644"
    variables(:hadoop => hadoop_config_hash)
    source "#{conf_file}.erb"
    hadoop_services.each do |svc|
      if startable?(node[:hadoop][svc])
        notifies :restart, "service[hadoop_#{svc}]", :delayed
      end
    end
  end
end

template "/etc/default/#{node[:hadoop][:handle]}" do
  owner "root"
  mode "0644"
  variables(:hadoop => hadoop_config_hash)
  source "etc_default_hadoop.erb"
end

# $HADOOP_NODENAME is set in /etc/default/hadoop
munge_one_line('use node name in hadoop .log logs', "#{node[:hadoop][:home_dir]}/bin/hadoop-daemon.sh",
  %q{export HADOOP_LOGFILE=hadoop-.HADOOP_IDENT_STRING-.command-.HOSTNAME.log},
   %q{export HADOOP_LOGFILE=hadoop-$HADOOP_IDENT_STRING-$command-$HADOOP_NODENAME.log},
  %q{^export HADOOP_LOGFILE.*HADOOP_NODENAME}
  )

munge_one_line('use node name in hadoop .out logs', "#{node[:hadoop][:home_dir]}/bin/hadoop-daemon.sh",
  %q{export _HADOOP_DAEMON_OUT=.HADOOP_LOG_DIR/hadoop-.HADOOP_IDENT_STRING-.command-.HOSTNAME.out},
  %q{export _HADOOP_DAEMON_OUT=$HADOOP_LOG_DIR/hadoop-$HADOOP_IDENT_STRING-$command-$HADOOP_NODENAME.out},
  %q{^export _HADOOP_DAEMON_OUT.*HADOOP_NODENAME}
  )
