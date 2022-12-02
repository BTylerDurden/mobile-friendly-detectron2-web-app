# adapted from: https://github.com/facebookresearch/detectron2/blob/master/docker/Dockerfile

# FROM nvidia/cuda:10.2-cudnn7-devel
FROM python:3.7
FROM nvidia/cuda:10.2-cudnn7-devel-ubuntu18.04

ENV DEBIAN_FRONTEND noninteractive
RUN rm /etc/apt/sources.list.d/cuda.list
RUN rm /etc/apt/sources.list.d/nvidia-ml.list

RUN apt-get update && apt-get install -y \
    python3.7 python3.7-dev python3.7-distutils \
    python3-opencv ca-certificates   git wget sudo ninja-build

# Make python3 available for python3.7
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 2
RUN update-alternatives --config python3
# Make python available for python3.7
RUN ln -sv /usr/bin/python3.7 /usr/bin/python

RUN apt-get update && apt-get install -y \
        python3-opencv ca-certificates python3-dev git wget sudo curl && \
  rm -rf /var/lib/apt/lists/*

# create a non-root user
ARG USER_ID=1000
RUN useradd -m --no-log-init --system  --uid ${USER_ID} appuser -g sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER appuser
WORKDIR /home/appuser

ENV PATH="/home/appuser/.local/bin:${PATH}"
RUN wget https://bootstrap.pypa.io/pip/get-pip.py && \
        python3.7 get-pip.py --user && \
        rm get-pip.py

# install dependencies
# See https://pytorch.org/ for other options if you use a different version of CUDA
RUN pip install --user tensorboard
RUN pip install --user numpy==1.20.3
RUN pip3 install --user torch==1.8.2+cu102 torchvision==0.9.2+cu102 torchaudio===0.8.2 -f https://download.pytorch.org/whl/lts/1.8/torch_lts.html

RUN pip install --user 'git+https://github.com/facebookresearch/fvcore'
# install detectron2
RUN git clone https://github.com/facebookresearch/detectron2 detectron2_repo
# set FORCE_CUDA because during `docker build` cuda is not accessible
ENV FORCE_CUDA="1"
# This will by default build detectron2 for all common cuda architectures and take a lot more time,
# because inside `docker build`, there is no way to tell which architecture will be used.
ARG TORCH_CUDA_ARCH_LIST="Kepler;Kepler+Tesla;Maxwell;Maxwell+Tegra;Pascal;Volta;Turing"
ENV TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST}"

RUN pip install --user -e detectron2_repo

# add dir
COPY requirements.txt /home/appuser/detectron2_repo
RUN pip install --user -r /home/appuser/detectron2_repo/requirements.txt
RUN pip install --user 'git+https://github.com/cocodataset/cocoapi.git#subdirectory=PythonAPI'


# Set a fixed model cache directory.
ENV FVCORE_CACHE="/tmp"
WORKDIR /home/appuser/detectron2_repo
ENV PILLOW_VERSION=7.0.0

# add dir
COPY . /home/appuser/detectron2_repo

# Make port 8080 available to the world outside the container
ENV PORT 8080
EXPOSE 8080

# CMD python app.py
CMD ["python3", "app.py"]
