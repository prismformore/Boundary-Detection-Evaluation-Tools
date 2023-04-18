# :fire: Boundary Detection Evaluation Tools 

##  :scroll: Introduction
The repository offers a user-friendly evaluation tool that encompasses all necessary components for boundary detection on PASCAL-Context and NYUD-v2 datasets.

The implementation is based on the Matlab-based [SEISM](https://github.com/jponttuset/seism) project to compute the optimal dataset F-measure scores. 

Identical to [ATRC](https://github.com/brdav/atrc), we use [maxDist](https://github.com/jponttuset/seism/blob/6af0cad37d40f5b4cbd6ca1d3606ec13b176c351/src/scripts/eval_method.m#L34)=0.0075 for PASCAL-Context and maxDist=0.011 for NYUD-v2. Thresholds for HED (under seism/parameters/HED.txt) are used. ```read_one_cont_png``` is used as IO function in SEISM.


## Useage
### 1. Build recommended environment
The code is tested under Python 3.7 and Matlab 8.6.0.267246 (R2015b)

### 2. Set up SEISM
-   Go to ```./seism```
-   Run ```matlab -nojvm -nodisplay -r "install"```
-   Go to ```./seism/gt_wrappers/db_root_dir.m```, and set your ground-truth dataset paths of PASCAL-Context and NYUD-v2.

### 3. Run evaluation codes
PASCAL-Context:
```bash
python eval_edge_pascal.py
```
NYUD-v2
```bash
python eval_edge_nyud.py
```

Before that, set the ```prediction_path``` in python files to the directory  containing the saved boundary detection prediction results. The expected folder for these predictions is named "edge". 

For example, if your saved directory is structred as  ```somepath/edge```, you should set ```prediction_path``` as ```somepath```.

You can assign any unique name of your choice to ```exp_name```.

# :hugs: Cite
Please check our works on multi-task scene understanding as this evaluation tool was initially developed for that purpose:
> [Hanrong Ye](https://sites.google.com/site/yhrspace/) and [Dan Xu](https://www.danxurgb.net/), [TaskPrompter: Spatial-Channel Multi-Task Prompting for Dense Scene Understanding](./TaskPrompter/README.md). 
> ICLR 2023

> [Hanrong Ye](https://sites.google.com/site/yhrspace/) and [Dan Xu](https://www.danxurgb.net/), [Inverted Pyramid Multi-task Transformer for Dense Scene Understanding](./InvPT/README.md). 
> ECCV 2022


BibTex:
```
@InProceedings{invpt2022,
  title={Inverted Pyramid Multi-task Transformer for Dense Scene Understanding},
  author={Ye, Hanrong and Xu, Dan},
  booktitle={ECCV},
  year={2022}
}
@InProceedings{taskprompter2023,
  title={TaskPrompter: Spatial-Channel Multi-Task Prompting for Dense Scene Understanding},
  author={Ye, Hanrong and Xu, Dan},
  booktitle={ICLR},
  year={2023}
}
```
Please do consider :star2: star our project to share with your community if you find this repository helpful!

# :blush: Contact
Please contact [Hanrong Ye](https://sites.google.com/site/yhrspace/) if any questions.

# :+1: Acknowledgement
This repository is a wrapper of [SEISM](https://github.com/jponttuset/seism). It is developed with partial code reference from [MTI-Net](https://github.com/SimonVandenhende/Multi-Task-Learning-PyTorch). 
