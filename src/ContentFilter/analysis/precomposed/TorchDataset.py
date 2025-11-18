import torch
from torch.utils.data import Dataset
import pandas as pd
from transformers import AutoTokenizer
import torch.nn as nn
import numpy as np

class TorchDataset(Dataset):
    def __init__(self, data: pd.DataFrame, tokenizer: AutoTokenizer, context_l: int, pad_token: int = 2):
        super(TorchDataset, self).__init__()
        self.data = data.reset_index(drop=True)
        self.tok = tokenizer
        self.context = context_l
        self.pad_token = pad_token

        required_columns = ['text', 'spam', 'toxic', 'ok']
        for col in required_columns:
            if col not in data.columns:
                raise ValueError(f"{col}")
        print("Let's go!")

    def __len__(self) -> int:
        return len(self.data)

    def __getitem__(self, idx) -> tuple:
        text = self.data.iloc[idx]['text']
        labels = self.data.iloc[idx][['spam', 'toxic', 'ok']].values.astype(np.float32)
        
        input_ids = self.precomposition(text)
        labels_tensor = torch.tensor(labels, dtype=torch.float32)
        
        return input_ids, labels_tensor

    def precomposition(self, text: str) -> torch.Tensor:
        encoded = self.tok.encode(text, return_tensors="pt").squeeze()
        padding_needed = self.context - len(encoded)
        
        if padding_needed > 0:
            padded_encoded = nn.functional.pad(
                encoded, (0, padding_needed),
                value=self.pad_token
            )
        elif padding_needed < 0:
            padded_encoded = encoded[-self.context:]
        else:
            padded_encoded = encoded

        return padded_encoded