import numpy as np
from fxpmath import Fxp
import pandas as pd

df_model = pd.read_csv('data.csv',index_col=False)
df_model = df_model.iloc[: , 1:] # remove row index
df_res   = pd.read_csv('res.csv')

fxp_vector = []

for n in range(0,24,3):
    DataHex = "0x"+str(df_res.iloc[0][n])
    QI      = str(df_res.iloc[0][n+1])
    QF      = str(df_res.iloc[0][n+2])
    Qstr    = "Q"+QI+"."+QF
    z1 = Fxp(DataHex, signed=True, dtype=Qstr)
    fxp_vector.append(z1)
    #print(z1)
    
FPGA_res = np.asarray(fxp_vector)

row_read = df_model.iloc[0].to_numpy()
matrix   =  row_read[0:64].reshape((8, 8)).astype(float)
c_vector =  row_read[64:72].astype(float)
optimal_res = matrix@c_vector.T

print(optimal_res)
print(FPGA_res)



"""
m1 = np.array([0.06255386215661352,	-0.07337269471208452, -0.03333358112738072, 
              0.9347724722812074  ,	-0.7013328990168586	, 0.7477932928671069,	
              -0.8571663033057699,	-0.047890995836945116])

m2 = np.array([-0.3220354505186618, -0.005584818082522425,-0.8732023268118279,
               -0.1391887438451953,	-0.2838363725595363,0.05636581796339768	
               ,-0.9288997256884848,-0.1446427145393283]).T

res = m1@m2
print(res)

z1 = Fxp('0x7630', signed=True, dtype='Q1.15')
print(z1.get_val())
"""