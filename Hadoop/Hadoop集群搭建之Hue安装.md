#### Hadoop集群搭建之Hue安装



```python
sudo yum install gcc gcc-c++ libffi-devel libxml2-devel libxslt-devel openldap-devel python-devel sqlite-devel openssl-devel gmp-devel cyrus-sasl-devel cyrus-sasl-gssapi cyrus-sasl-plain krb5-devel

```

```
--- Building egg for MySQL-python-1.2.5
sh: mysql_config: command not found
Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/sandbox.py", line 253, in run_setup
    raise
  File "/usr/lib64/python2.7/contextlib.py", line 35, in __exit__
    self.gen.throw(type, value, traceback)
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/sandbox.py", line 195, in setup_context
    yield
  File "/usr/lib64/python2.7/contextlib.py", line 35, in __exit__
    self.gen.throw(type, value, traceback)
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/sandbox.py", line 166, in save_modules
    saved_exc.resume()
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/sandbox.py", line 141, in resume
    six.reraise(type, exc, self._tb)
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/sandbox.py", line 154, in save_modules
    yield saved
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/sandbox.py", line 195, in setup_context
    yield
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/sandbox.py", line 250, in run_setup
    _execfile(setup_script, ns)
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/sandbox.py", line 45, in _execfile
    exec(code, globals, locals)
  File "setup.py", line 17, in <module>
    metadata, options = get_config()
  File "/opt/apps/hue-4.7.1/desktop/core/ext-py/MySQL-python-1.2.5/setup_posix.py", line 43, in get_config
    libs = mysql_config("libs_r")
  File "/opt/apps/hue-4.7.1/desktop/core/ext-py/MySQL-python-1.2.5/setup_posix.py", line 25, in mysql_config
    raise EnvironmentError("%s not found" % (mysql_config.path,))
EnvironmentError: mysql_config not found
make[2]: *** [/opt/apps/hue-4.7.1/desktop/core/build/MySQL-python-1.2.5/egg.stamp] Error 1
make[2]: Leaving directory `/opt/apps/hue-4.7.1/desktop/core'
make[1]: *** [.recursive-env-install/core] Error 2
make[1]: Leaving directory `/opt/apps/hue-4.7.1/desktop'
make: *** [desktop] Error 2



mysql-devel
```

```
[hadoop@master hue-4.7.1]$ ./build/env/bin/easy_install ipython==5.2.0
WARNING: The easy_install command is deprecated and will be removed in a future version.
Searching for ipython==5.2.0
Best match: ipython 5.2.0
Processing ipython-5.2.0-py2.7.egg
ipython 5.2.0 is already the active version in easy-install.pth
Installing ipython script to /opt/apps/hue-4.7.1/build/env/bin
Installing iptest2 script to /opt/apps/hue-4.7.1/build/env/bin
Installing iptest script to /opt/apps/hue-4.7.1/build/env/bin
Installing ipython2 script to /opt/apps/hue-4.7.1/build/env/bin

Using /opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/ipython-5.2.0-py2.7.egg
Processing dependencies for ipython==5.2.0
Searching for traitlets>=4.2
Reading https://pypi.tuna.tsinghua.edu.cn/simple/traitlets/
Downloading https://pypi.tuna.tsinghua.edu.cn/packages/5e/3a/f510eeb8388cf4028c690faec22843176772f5e59c8d418e8268d71ebd7a/traitlets-5.0.4.tar.gz#sha256=86c9351f94f95de9db8a04ad8e892da299a088a64fd283f9f6f18770ae5eae1b
Best match: traitlets 5.0.4
Processing traitlets-5.0.4.tar.gz
Writing /tmp/easy_install-KfzkNd/traitlets-5.0.4/setup.cfg
Running traitlets-5.0.4/setup.py -q bdist_egg --dist-dir /tmp/easy_install-KfzkNd/traitlets-5.0.4/egg-dist-tmp-AiV4b5
Traceback (most recent call last):
  File "./build/env/bin/easy_install", line 11, in <module>
    sys.exit(main())
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/command/easy_install.py", line 2321, in main
    **kw
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/__init__.py", line 162, in setup
    return distutils.core.setup(**attrs)
  File "/usr/lib64/python2.7/distutils/core.py", line 152, in setup
    dist.run_commands()
  File "/usr/lib64/python2.7/distutils/dist.py", line 953, in run_commands
    self.run_command(cmd)
  File "/usr/lib64/python2.7/distutils/dist.py", line 972, in run_command
    cmd_obj.run()
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/command/easy_install.py", line 424, in run
    self.easy_install(spec, not self.no_deps)
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/command/easy_install.py", line 685, in easy_install
    return self.install_item(spec, dist.location, tmpdir, deps)
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/command/easy_install.py", line 716, in install_item
    self.process_distribution(spec, dists[0], deps, "Using")
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/command/easy_install.py", line 758, in process_distribution
    [requirement], self.local_index, self.easy_install
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/pkg_resources/__init__.py", line 782, in resolve
    replace_conflicting=replace_conflicting
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/pkg_resources/__init__.py", line 1065, in best_match
    return self.obtain(req, installer)
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/pkg_resources/__init__.py", line 1077, in obtain
    return installer(requirement)
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/command/easy_install.py", line 685, in easy_install
    return self.install_item(spec, dist.location, tmpdir, deps)
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/command/easy_install.py", line 711, in install_item
    dists = self.install_eggs(spec, download, tmpdir)
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/command/easy_install.py", line 896, in install_eggs
    return self.build_and_install(setup_script, setup_base)
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/command/easy_install.py", line 1164, in build_and_install
    self.run_setup(setup_script, setup_base, args)
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/command/easy_install.py", line 1150, in run_setup
    run_setup(setup_script, args)
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/sandbox.py", line 253, in run_setup
    raise
  File "/usr/lib64/python2.7/contextlib.py", line 35, in __exit__
    self.gen.throw(type, value, traceback)
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/sandbox.py", line 195, in setup_context
    yield
  File "/usr/lib64/python2.7/contextlib.py", line 35, in __exit__
    self.gen.throw(type, value, traceback)
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/sandbox.py", line 166, in save_modules
    saved_exc.resume()
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/sandbox.py", line 141, in resume
    six.reraise(type, exc, self._tb)
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/sandbox.py", line 154, in save_modules
    yield saved
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/sandbox.py", line 195, in setup_context
    yield
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/sandbox.py", line 250, in run_setup
    _execfile(setup_script, ns)
  File "/opt/apps/hue-4.7.1/build/env/lib/python2.7/site-packages/setuptools/sandbox.py", line 44, in _execfile
    code = compile(script, filename, 'exec')
  File "/tmp/easy_install-KfzkNd/traitlets-5.0.4/setup.py", line 41
    print(error, file=sys.stderr)
                     ^
SyntaxError: invalid syntax




./build/env/bin/python -m pip install ipython==5.2.0
./build/env/bin/python -m pip install ipdb==0.10.3
./build/env/bin/python -m pip install nose==1.3.7
./build/env/bin/python -m pip install coverage==4.4.2
./build/env/bin/python -m pip install nosetty==0.4
./build/env/bin/python -m pip install werkzeug==0.14.1
./build/env/bin/python -m pip install windmill==1.6
./build/env/bin/python -m pip install astroid==1.5.3
./build/env/bin/python -m pip install isort==4.2.5
./build/env/bin/python -m pip install six==1.10.0
```



```
sudo yum install epel-release
sudo yum install nodejs

npm config set registry https://registry.npm.taobao.org
```

