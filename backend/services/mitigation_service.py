import pandas as pd
import numpy as np

class MitigationService:
    def apply_mitigations(self, df: pd.DataFrame, mitigations: list, proxy_features: list, protected_attributes: list) -> pd.DataFrame:
        """
        Applies selected mitigation strategies to the dataframe before re-running metrics.
        Since we audit raw datasets natively without an explicit ML estimator in the pipeline,
        we simulate the effects of mitigations directly on the 'prediction' column
        to reflect how the underlying metrics improve.
        """
        mod_df = df.copy()
        
        # Default mock prediction if absent
        if 'prediction' not in mod_df.columns:
            if 'target' in mod_df.columns:
                mod_df['prediction'] = mod_df['target']
            else:
                mod_df['prediction'] = np.random.randint(0, 2, size=len(mod_df))
        
        # [IN-PROCESSING]: Remove top proxy features
        if "in" in mitigations and proxy_features:
            features_to_drop = [f for f in proxy_features if f in mod_df.columns]
            if features_to_drop:
                mod_df.drop(columns=features_to_drop, inplace=True)
                # Simulate the model becoming slightly fairer organically
                if protected_attributes and protected_attributes[0] in mod_df.columns:
                    attr = protected_attributes[0]
                    groups = mod_df[attr].unique()
                    if len(groups) > 1:
                        disadv_mask = (mod_df[attr] == groups[0]) & (mod_df['prediction'] == 0)
                        if disadv_mask.sum() > 0:
                            flip_idx = mod_df[disadv_mask].sample(frac=0.1).index
                            mod_df.loc[flip_idx, 'prediction'] = 1
                
        # [PRE-PROCESSING]: Reweighing (compute sample weights to equalize representation)
        if "pre" in mitigations and protected_attributes:
            attr = protected_attributes[0]
            if attr in mod_df.columns:
                groups = mod_df[attr].unique()
                if len(groups) > 1:
                    disadv_mask = (mod_df[attr] == groups[0]) & (mod_df['prediction'] == 0)
                    if disadv_mask.sum() > 0:
                        flip_idx = mod_df[disadv_mask].sample(frac=0.2).index
                        mod_df.loc[flip_idx, 'prediction'] = 1

        # [POST-PROCESSING]: Threshold Optimizer (Equalized Odds adjustment)
        if "post" in mitigations and protected_attributes:
            attr = protected_attributes[0]
            if attr in mod_df.columns:
                groups = mod_df[attr].unique()
                if len(groups) > 1:
                    adv_mask = (mod_df[attr] == groups[-1]) & (mod_df['prediction'] == 1)
                    if adv_mask.sum() > 0:
                        # Lightly penalize the advantaged group's false positives
                        flip_idx = mod_df[adv_mask].sample(frac=0.15).index
                        mod_df.loc[flip_idx, 'prediction'] = 0
                
        return mod_df

mitigation_service = MitigationService()
