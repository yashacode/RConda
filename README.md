# RConda
Tools for generating a conda environment for an R package

In your R project root directory, run this to make a yaml of required packages from the DESCRIPTION file.
```
make_yaml()
```

Then tell your user to do the following to make a Conda env:

1) In R run the following to get the yaml path:
```
# replace yourpackage with your package name
system.file("extdata", "yourpackage-env.yml", package = "yourpackage")
```

2) In the terminal run this to make the conda env:
```
conda env create -f "/full/path/to/yourpackage-env.yml"
```
