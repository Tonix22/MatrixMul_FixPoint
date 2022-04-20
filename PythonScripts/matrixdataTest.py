import numpy as np
from fxpmath import Fxp
import pandas as pd
import math

df_model = pd.read_csv('data.csv',index_col=False)
df_model = df_model.iloc[: , 1:] # remove row index
df_res   = pd.read_csv('res.csv')

opt = []
estimate = []

for i in range(0,999):
    #print()
    #print("****** iteration: "+str(i)+"*******")
    #print()
    #ideal FPU
    row_read = df_model.iloc[i*2].to_numpy()
    matrix   =  row_read[0:64].reshape((8, 8)).astype(float)
    c_vector =  row_read[64:72].astype(float)
    optimal_res = matrix@c_vector.T
    
    #FXP
    fxp_vector = []
    for n in range(0,24,3):
        DataHex = "0x"+str(df_res.iloc[i][n])
        QI      = str(df_res.iloc[i][n+1])
        QF      = str(df_res.iloc[i][n+2])
        Qstr    = "Q"+QI+"."+QF
        z1 = Fxp(DataHex, signed=True, dtype=Qstr)
        fxp_vector.append(z1)
        #print(z1)
        
    FPGA_res = np.asarray(fxp_vector)

    
    opt.append(math.sqrt((optimal_res@optimal_res.T)/8))
    estimate.append(math.sqrt((FPGA_res@FPGA_res.T)/8))


opt_np = np.asarray(opt)
res_np = np.asarray(estimate)

P_opt  = np.average(opt_np) 
P_res  = np.average(res_np)

SQNR   = 10*math.log(P_res/P_opt)

print("SQNR: ",end='')
print(SQNR,end='')
print(" dB")