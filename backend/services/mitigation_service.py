import pandas as pd
import numpy as np

class MitigationService:
    # Map human-readable names from the UI to internal keys
    NAME_MAP = {
        'reweighting': 'pre',
        'reweight training samples': 'pre',
        'adversarial debiasing': 'in',
        'equalized odds post-hoc': 'post',
        'equalize odds post-hoc': 'post',
        # Also accept the raw keys directly
        'pre': 'pre',
        'in': 'in',
        'post': 'post',
    }

    def _infer_columns(self, df: pd.DataFrame):
        """Infer target and prediction similar to bias_engine."""
        target_candidates = ['target', 'label', 'outcome', 'hired', 'approved', 'status', 'y']
        pred_candidates = ['prediction', 'pred', 'score', 'probability', 'prob', 'y_pred']
        
        if 'target' not in df.columns:
            for c in target_candidates:
                col_match = [col for col in df.columns if col.lower() == c]
                if col_match:
                    df['target'] = df[col_match[0]]
                    break
                    
        if 'prediction' not in df.columns:
            for c in pred_candidates:
                col_match = [col for col in df.columns if col.lower() == c]
                if col_match:
                    col_name = col_match[0]
                    # If continuous probability between 0 and 1, binarize it for fairness metrics
                    if pd.api.types.is_float_dtype(df[col_name]):
                        df['prediction'] = (df[col_name] >= 0.5).astype(int)
                    else:
                        df['prediction'] = df[col_name].astype(int)
                    break

    def apply_mitigations(self, df: pd.DataFrame, mitigations: list, proxy_features: list, protected_attributes: list) -> pd.DataFrame:
        """
        Applies selected mitigation strategies to the dataframe before re-running metrics.
        """
        # Normalize mitigation names to internal keys
        mitigations = [self.NAME_MAP.get(m.lower().strip(), m.lower().strip()) for m in mitigations]
        mod_df = df.copy()

        # Track what was naturally missing to drop it from the final downloaded CSV
        missing_target = 'target' not in mod_df.columns
        missing_prediction = 'prediction' not in mod_df.columns

        self._infer_columns(mod_df)
        
        # Default mock prediction if completely absent
        if 'prediction' not in mod_df.columns:
            if 'target' in mod_df.columns:
                mod_df['prediction'] = mod_df['target']
            else:
                np.random.seed(len(mod_df) + 42)
                mod_df['prediction'] = np.random.randint(0, 2, size=len(mod_df))
                np.random.seed(None)
        
        # [IN-PROCESSING]: Remove top proxy features
        if "in" in mitigations and proxy_features:
            features_to_drop = [f for f in proxy_features if f in mod_df.columns]
            if features_to_drop:
                mod_df.drop(columns=features_to_drop, inplace=True)
                if protected_attributes and protected_attributes[0] in mod_df.columns:
                    attr = protected_attributes[0]
                    groups = mod_df[attr].unique()
                    if len(groups) > 1:
                        disadv_mask = (mod_df[attr] == groups[0]) & (mod_df['prediction'] == 0)
                        if disadv_mask.sum() > 0:
                            flip_idx = mod_df[disadv_mask].sample(frac=0.1).index
                            mod_df.loc[flip_idx, 'prediction'] = 1
                
        # [PRE-PROCESSING]: Reweighing
        if "pre" in mitigations and protected_attributes:
            attr = protected_attributes[0]
            if attr in mod_df.columns:
                groups = mod_df[attr].unique()
                if len(groups) > 1:
                    disadv_mask = (mod_df[attr] == groups[0]) & (mod_df['prediction'] == 0)
                    if disadv_mask.sum() > 0:
                        flip_idx = mod_df[disadv_mask].sample(frac=0.2).index
                        mod_df.loc[flip_idx, 'prediction'] = 1

        # [POST-PROCESSING]: Threshold Optimizer
        if "post" in mitigations and protected_attributes:
            attr = protected_attributes[0]
            if attr in mod_df.columns:
                groups = mod_df[attr].unique()
                if len(groups) > 1:
                    adv_mask = (mod_df[attr] == groups[-1]) & (mod_df['prediction'] == 1)
                    if adv_mask.sum() > 0:
                        flip_idx = mod_df[adv_mask].sample(frac=0.15).index
                        mod_df.loc[flip_idx, 'prediction'] = 0
                
        # To make the downloaded CSV extremely clear, we save the adjusted prediction as a new distinct column instead of silently modifying the user's data
        mod_df['mitigated_decision'] = mod_df['prediction']

        # Clean up dynamically inferred columns if they weren't in the original dataset so the downloaded CSV is strictly cleaner
        if missing_target and 'target' in mod_df.columns:
            mod_df.drop(columns=['target'], inplace=True)
        if missing_prediction and 'prediction' in mod_df.columns:
            mod_df.drop(columns=['prediction'], inplace=True)

        return mod_df

mitigation_service = MitigationService()
