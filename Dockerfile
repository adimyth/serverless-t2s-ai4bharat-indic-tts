FROM runpod/base:0.4.0-cuda11.8.0

# Set working directory
RUN mkdir -p /usr/ai-inference/
WORKDIR /usr/ai-inference/

# Install system dependencies
RUN apt-get update \
    && apt-get -y install git g++ gcc postgresql libpq-dev python-dev wget unzip vim curl \
    && apt-get -y install poppler-utils ffmpeg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Additional requirements for IndicTrans2 - https://github.com/AI4Bharat/IndicTrans2/blob/main/huggingface_interface/colab_inference.ipynb (setup section)
RUN pip install nltk sacremoses pandas regex mock transformers>=4.33.2 mosestokenizer
RUN python3 -c "import nltk; nltk.download('punkt')"
RUN pip install bitsandbytes scipy accelerate datasets
RUN pip install sentencepiece

RUN git clone https://github.com/VarunGumma/IndicTransTokenizer
RUN cd IndicTransTokenizer && pip install -e .

# Download Indic-TTS models 
RUN mkdir -p /usr/ai-inference/models/v1

# Hindi
RUN wget https://github.com/AI4Bharat/Indic-TTS/releases/download/v1-checkpoints-release/hi.zip && unzip hi.zip -d /usr/ai-inference/models/v1 && rm hi.zip
# Kannada
RUN wget https://github.com/AI4Bharat/Indic-TTS/releases/download/v1-checkpoints-release/kn.zip && unzip kn.zip -d /usr/ai-inference/models/v1 && rm kn.zip
# Tamil
RUN wget https://github.com/AI4Bharat/Indic-TTS/releases/download/v1-checkpoints-release/ta.zip && unzip ta.zip -d /usr/ai-inference/models/v1 && rm ta.zip
# Telugu
RUN wget https://github.com/AI4Bharat/Indic-TTS/releases/download/v1-checkpoints-release/te.zip && unzip te.zip -d /usr/ai-inference/models/v1 && rm te.zip

# Install TTS dependencies
RUN git clone https://github.com/gokulkarthik/TTS
RUN cd TTS && pip3 install -e .[all]
RUN cd ..

# Python dependencies
COPY builder/requirements.txt /requirements.txt
RUN python3.11 -m pip install --upgrade pip && \
    python3.11 -m pip install --upgrade -r /requirements.txt --no-cache-dir && \
    rm /requirements.txt

# Add src files
ADD src .

CMD python3.11 -u /handler.py