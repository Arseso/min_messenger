from enum import Enum
import logging
import torch
from transformers import AutoConfig, AutoTokenizer, AutoModelForSequenceClassification
from typing import Dict, Any
import numpy as np

from models import VERDICT

class Verdict(str, Enum):
    SPAM = "SPAM"
    TOXIC = "TOXIC" 
    OK = "OK"

class NeuralNet:
    def __init__(self, model_repo: str):
        try:
            self.tokenizer = AutoTokenizer.from_pretrained(model_repo)
            
            if self.tokenizer.pad_token is None:
                self.tokenizer.pad_token = self.tokenizer.eos_token
            
            self.model = AutoModelForSequenceClassification.from_pretrained(
                model_repo,
                num_labels=3,
                ignore_mismatched_sizes=True
            )
            self.model.eval()
            self._model_loaded = True
            logging.basicConfig(
                level=logging.INFO,
                format='%(asctime)s - %(threadName)s - %(message)s'
            )
            logging.info(f"Model successfully downloaded from {model_repo}")
            
        except Exception as e:
            print(f"⚠️  Не удалось загрузить модель: {e}")
            print("🔄 Используется заглушка")
            self._model_loaded = False
    
    def predict(self, text: str) -> Verdict:
        if not self._model_loaded:
            return Verdict.OK
        
        try:
            text = text.lower().replace(" ", "")
            
            inputs = self.tokenizer(
                text, 
                return_tensors="pt",
                truncation=True,
                padding=True,
                max_length=512
            )
            
            if 'token_type_ids' in inputs:
                inputs.pop('token_type_ids')
            
            with torch.no_grad():
                outputs = self.model(**inputs)
                
                if hasattr(outputs, 'logits'):
                    logits = outputs.logits
                else:
                    return Verdict.OK
                
                probabilities = torch.nn.functional.softmax(logits, dim=-1)
                probs = probabilities.cpu().numpy()[0]
                
                if np.max(probs) < 0.8:
                    return Verdict.OK
                
                predicted_label = int(np.argmax(probs))
                
                return [Verdict.SPAM, Verdict.TOXIC, Verdict.OK][predicted_label]
                
        except Exception as e:
            print(f"⚠️  Ошибка в predict: {e}")
            return Verdict.OK


if __name__ == "__main__":
    from env import Settings
    nn = NeuralNet(model_repo=Settings.MODEL_REPO)
    tests = [
        "Привет как дела", # SPAM и нехуй спорить мисье тестировщик
        "виагра 1500 рублей скидка",
        "Ты идиот",
        "Хорошая погода сегодня"
    ]

    for text in tests:
        result = nn.predict(text)
        print(f"'{text}' -> {result}")