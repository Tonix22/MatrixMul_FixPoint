import numpy as np
from fxpmath import Fxp
import pandas as pd

REALIZATIONS = 1000
ROW_SIZE     = 8
RESULT_SIZE  = 8
MATRIX_SIZE  = ROW_SIZE*ROW_SIZE


df = pd.DataFrame(index=np.arange(REALIZATIONS*2), columns=np.arange(MATRIX_SIZE+ROW_SIZE+RESULT_SIZE))
np.set_printoptions(suppress=True,
   formatter={'float_kind':'{:2.17f}'.format})

pd.set_option('display.float_format', lambda x: '%.40f' % x)

for n in range (0,REALIZATIONS):
    #Flatten matrix 2D in a 1D array
    rand_arry = np.random.uniform(-1.0,1,MATRIX_SIZE)
    #reshaping used to get optimial multiplication
    matrix    = np.reshape(rand_arry,(ROW_SIZE,ROW_SIZE))
    #Vector Generation
    vector    = np.random.uniform(-1.0,1,ROW_SIZE)
    #optimal value, 
    #FXP will aproach to this value using only 16 bits
    f_result = matrix@vector.T

    #FXP generation truncation is done by the internal 
    #library with the QIF required.
    z1 = Fxp(rand_arry, signed=True, dtype='Q2.14')
    z2 = Fxp(vector, signed=True, dtype='Q2.14')
    
    #Save data in pandas data frame
    df.loc[n*2,0:63]    = rand_arry
    df.loc[n*2,64:71]   = vector
    df.loc[n*2,72:79]   = f_result

    for m in range(0,64):
        df.loc[n*2+1,m]  = z1[m].hex() 
    for m in range(0,8):
        df.loc[n*2+1,m+64]  = z2[m].hex() 

df.to_csv('data.csv')
#print(z1.bin(frac_dot=True))