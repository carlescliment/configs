# Jenkins

- ** Ubuntu **
- ** Subversion **


## Install and upgrade jenkins
apt-get install jenkins

Go to [the admin panel](http://localhost:8080/manage), download the latest release and replace the existing jenkins.war file (probably in `/usr/share/jenkins`).

## Install plugins
Go to the manage plugins version and install the following:

- Ant plugin
- PHP plugin



## Create a workspace folder

`mkdir /var/ci/jenkins/your-project`

Follow the instructions in the PHP Under Control [Configure the project](phpundercontrol.md#configure-the-project) section.


Grant permissions to the jenkins user

```
setfacl -R -m u:jenkins:rwX -m u:`whoami`:rwX /var/ci/jenkins
setfacl -dR -m u:jenkins:rwX -m u:`whoami`:rwX /var/ci/jenkins
```

## Create a jenkins project
Go to jenkins and create a new project. This are the settings you should add:

- In “advanced project options” set “Use custom workspace” to “/var/ci/jenkins/your-project”
- In “source code management” select “None”
- In build triggers select “Build periodically” with “*/5 9-18 * * 1-5”
- In “Add Build action” add an ant step with the target “slow_build”.
- In “Add Postbuild action” select “Publis jUnit test report” and set it to search for “**/_log/report.xml”.
- Add a post build action to send an email to the addresses you want.

