# PHP Under Control

Initial setup **for a project managed by subversion**.

## Install dependencies

```
$ apt-get install subversion
$ apt-get install java-common
$ apt-get install ant

sendmail, postfix or other mail platforms
```

## Download CruiseControl

Download the latest version from the [official webpage](http://cruisecontrol.sourceforge.net/download.html) and extract it wherever you want.

Suggested: `/var/ci/cruise-control`



## Create a project folder

For example `/var/ci/cruise-control/projects/your-project`
[Download svn ant](http://subclipse.tigris.org/files/documents/906/49042/svnant-1.3.1.zip).
Extract the svnant lib folder inside the project directory, so that you have something like `/var/ci/cruise-control/projects/your-project/lib`.



## Create a `build-properties` file in your project folder

```
# -----------------------------------------------------------------------------
# build.properties
# This file is referenced by the build.xml file.
# -----------------------------------------------------------------------------

svnant.version=1.3.1

# -----------------------------------------------------------------------------
# all jar needed
# -----------------------------------------------------------------------------
lib.dir=lib

svnant.repository.user=your_svn_user
svnant.repository.passwd=your_svn_password
```

## Put a build.xml file in your project folder

Have a look at [this example](/ant_tasks/build.xml). It defines a set of tasks, each one identified by a <target> tag, that can be executed in isolation:

* `ant checkout` -> brings a new copy of the repository
* `ant update` -> updates an existing copy  of the repository
* `ant composer` -> updates the integration environment dependencies with composer
* `ant unit` -> executes phpunit tests
* `ant acceptance` -> executes codeception tests
* `ant clean` -> cleans up the integration environment

Moreover, there are two complex tasks than combine the previous:

* `ant quick_build` -> updates an existing copy, executes composer and runs all tests
* `ant slow_build` -> brings a new copy from the repository, executes composer and runs all tests




## Configure the project in CruiseControl

Look at the CruiseControl root dir. You should see a build.xml file inside. Write the configuration needed for your project.

```
<cruisecontrol>
    <project name="your-project">
        <listeners>
                <currentbuildstatuslistener file="logs/${project.name}/status.txt"/>
        </listeners>

        <bootstrappers>
                <antbootstrapper anthome="apache-ant-1.7.0" buildfile="projects/${project.name}/build.xml" target="slow_build" />
        </bootstrappers>

        <schedule interval="300">
                <ant anthome="apache-ant-1.7.0" buildfile="projects/${project.name}/build.xml" target="slow_build" />
            </schedule>

            <log>
            <merge dir="projects/${project.name}/target/test-results"/>
        </log>
    </project>
</cruisecontrol>
```


The previous xml executes the slow_build task every 5 minutes.


## Patch CruiseControl with PHPUnderControl

```
git clone git://github.com/phpundercontrol/phpUnderControl.git
phpUnderControl/bin/phpuc(.php|.bat) install /path/to/cruisecontrol
```


## Go to the dashboard and enjoy

http://localhost:8080/dashboard/tab/dashboard



## Issues

Sometimes the execution is broken and shows the following message.

`Could not read response body: SSL error: decryption failed`

It doesn’t happens always, and may be involved with the server-side configuration. I initially thought it was due to the authentication caching, but even disabling this, the problem persists.


Finaly it seems a problem in the server side. Seems that the provider finally solved it.




