# TBEC RSC 8bits RTL implementation
The document aims to describe the algorithm used in RTL to encode 8bits of memory in TBEC RSC.

# Encode
`data_in` is the 8bits input of the algorithm and `data_out` is the 16bits output of the algorithm. The code of this implementation can be found at [rtl/tbec_rsc_encoder.sv](../rtl/tbec_rsc_encoder.sv).

data_in = {b<sub>7</sub>, b<sub>6</sub>, b<sub>5</sub>, b<sub>4</sub>, b<sub>3</sub>, b<sub>2</sub>, b<sub>1</sub>, b<sub>0</sub>}

Di<sub>0</sub> = b<sub>0</sub> ⊕ b<sub>2</sub> ⊕ b<sub>5</sub>, b<sub>7</sub>
Di<sub>1</sub> = b<sub>1</sub> ⊕ b<sub>3</sub> ⊕ b<sub>4</sub>, b<sub>6</sub>

P<sub>0</sub> = b<sub>0</sub> ⊕ b<sub>1</sub> ⊕ b<sub>4</sub>, b<sub>5</sub>
P<sub>1</sub> = b<sub>2</sub> ⊕ b<sub>3</sub> ⊕ b<sub>6</sub>, b<sub>7</sub>

Cb<sub>0,0</sub> = b<sub>0</sub> ⊕ b<sub>2</sub>
Cb<sub>0,1</sub> = b<sub>4</sub> ⊕ b<sub>6</sub>
Cb<sub>1,0</sub> = b<sub>1</sub> ⊕ b<sub>3</sub>
Cb<sub>1,1</sub> = b<sub>5</sub> ⊕ b<sub>7</sub>

data_out = {Cb<sub>1,1</sub>, Cb<sub>1,0</sub>, Cb<sub>0,1</sub>, Cb<sub>0,0</sub>, P<sub>1</sub>, P<sub>0</sub>, Di<sub>1</sub>, Di<sub>0</sub>, b<sub>7</sub>, b<sub>6</sub>, b<sub>5</sub>, b<sub>4</sub>, b<sub>3</sub>, b<sub>2</sub>, b<sub>1</sub>, b<sub>0</sub>}
