# Sonar

Sonar for **PHP**.

## Download and unzip
This is the [download link](http://docs.codehaus.org/display/SONAR/Setup+and+Upgrade).
Run the proper binary:

`./sonar.sh start`

## Install PHP plugins
Go to localhost:9000 and login as admin/admin
Go to update center in the admin section and install the PHP plugin

## Install Sonar Ant Task
http://docs.codehaus.org/display/SONAR/Installing+and+Configuring+SonarQube+Ant+Task

Put it in /usr/share/ant/lib

## Create the ant task

You can reuse [this example](/ant_tasks/build.xml)


## Execute the build

```
$ ant sonar
```