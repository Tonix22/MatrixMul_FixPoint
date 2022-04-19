from fxpmath import Fxp
x = Fxp(-0.3220354505186618,signed=True, dtype='Q2.14')
y = Fxp(0.06255386215661352,signed=True, dtype='Q2.14')
res = Fxp(None, signed=True,dtype='Q2.14')
res.equal(x*y)
"""
print(x.astype(float))
print(y.astype(float))
print(res.astype(float))
"""

print(x.hex())
print(y.hex())
print(res.hex())

print(x.bin(frac_dot=True))
print(y.bin(frac_dot=True))
print(res.bin(frac_dot=True))
"""

"""