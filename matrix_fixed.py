import numpy as np
from fxpmath import Fxp


def mult_fix(a,b):
    result = []
    #fixed point start with this Q int,frac values. 
    for n in range(0,len(a)):
        #Sum first value is 'Q2.14'. Int has 2 because the sign.
        frac = 14
        int_part = 1
        sum      = Fxp(signed=True, n_int=int_part,n_frac=frac)
        temp_sum = Fxp(signed=True, n_int=int_part,n_frac=frac)
        
        for m in range(0,len(a[n])):
            product = Fxp(signed=True,  n_int=int_part,n_frac=frac)
            #MAC
            product.equal(a[n][m]*b[m])
            temp_sum.equal(temp_sum+product)
            #Check overflow to extend integera part and reduce fractionational resolution
            if(temp_sum.status['overflow'] == True):
                frac   = frac -1
                int_part = int_part+1
                sum.resize(True, frac+int_part+1, frac)
                temp_sum.resize(True, frac+int_part+1, frac)
                sum.equal(sum + product)
                temp_sum.status['overflow'] = False
            else:
                sum.equal(temp_sum)
                
        result.append(sum.copy())
        
    res = Fxp(result)
    return res

m1 = np.array([[.99, .99,.99], [.7, .4,.1],[.7,.3, .9]])
m2 = np.array([1, 1, 1]).T
f_result = m1@m2

print(f_result)
z1 = Fxp(m1, signed=True, dtype='Q2.14')
z2 = Fxp(m2, signed=True, dtype='Q2.14')
res = mult_fix(z1,z2)

print(res)
print(res.info(verbose=3))
print(res.bin(frac_dot=True))