Hi! this repo is for my personal website where I collect my personal jupyter notebooks on different things I'm experimenting with.
---
Below is my airflow DAG for building the ipynb notebook files, rendering the website using Quarto, and deploying the _site directory to the gh-pages branch:

![image](https://github.com/nrenzoni/nrenzoni.github.io/assets/31897391/1b892284-b380-46f6-9f54-141497ca0112)

Each of the airflow DAG steps uses a similar bash command: ```. build_funcs.sh && {bash_command}```.
