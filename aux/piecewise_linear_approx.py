#!/usr/bin/env python

import numpy as np

### Hyperparameters
function = lambda x: 1. - np.tanh(x) ** 2
num_line_segments = 6
num_samples = 10**6
x_range = [-25,25]
err_slack = 1e-4
epochs = 10000
lr = 1e-3
e_guard = 1e-8
e_lr    = 0.005
break_epoch = 100
err_cutoff = 2.5


### Parameters
breakpoints = np.linspace(*(np.array(x_range)/2), num_line_segments-1)
slope       = np.random.rand(num_line_segments-2) / (num_line_segments-2)
y_intercept = np.random.rand(num_line_segments)   / num_line_segments
err = float('inf')
epoch = 0
epoch_counter = 0

# print(breakpoints)
# print(slope)
# print(y_intercept)

### Constants
x = np.linspace(*x_range, num_samples)
y = function(x)
best_breakpoints = breakpoints
best_slope       = slope      
best_y_intercept = y_intercept
best_err         = err
best_epoch       = 0

function_hat = lambda x : np.piecewise(
    x,
    [ x < breakpoints[0] if _iter == 0 else
      np.logical_and(breakpoints[_iter-1] <= x, x < breakpoints[_iter])
        for _iter in range(num_line_segments-1) 
    ],
    [
        lambda x : slope[_iter-1]*x + y_intercept[_iter] 
            if _iter not in [0, num_line_segments-1]
            else y_intercept[_iter]
            for _iter in range(num_line_segments)
                
    ]
)

def limiter(dx, limit):
    return np.where(
        np.abs(dx) > limit,
        limit * np.sign(dx),
        dx
    )

#
# dy = a * dx + da * x + db => da = dy/x, db = dy
# d(RMSE) = 1/2 * d(MSE) / RMSE = 1/2 * 2/N * SUM((y-y_hat)*d(y-y_hat)) / RMSE = 
#           1 / N / RMSE * SUM(dy_hat * (diff)) => dy_hat = N * RMSE * d(RMSE) / (y-y_hat)

while err > err_slack :
    epoch += 1

    # Calculate the Piecewise linear approximation
    y_hat = function_hat(x)

    # Calculate the error of each point
    dy = y - y_hat

    # Calculate the Mean square error
    err = np.sqrt(np.mean(dy**2))

    if err < best_err:
        best_breakpoints = breakpoints
        best_slope       = slope      
        best_y_intercept = y_intercept
        best_err         = err
        best_epoch       = epoch
        epoch_counter    = 0
    else :
        epoch_counter += 1

    if err < err_slack or err == float('NaN') or epoch_counter == break_epoch:
        break

    print("Epoch : ", epoch, " Error : ",err)
    # Backpropagate error
    dy_hat = lr * np.where(
        np.abs(dy) < err_slack,
        0,
        err / dy
        # np.sign(dy) * err / (np.abs(dy) + e_guard)
    )
    dy_hat = limiter(dy_hat, err_cutoff)

    dslope = dy_hat / x

    mask = np.digitize(x, [float('-inf'), *breakpoints, float('+inf')], right=False)
    
    dslope = np.array([
        np.mean(
            dslope[mask == _iter]
        ) if np.sum(mask == _iter) else 0
            for _iter in range(num_line_segments)
    ])
    dy_intercept = np.array([
        np.mean(
            dy_hat[mask == _iter]
        ) if np.sum(mask == _iter) else 0
            for _iter in range(num_line_segments)
    ])
    dslope = limiter(dslope, err_cutoff)
    dy_intercept = limiter(dy_intercept, err_cutoff)

    # Set continuity on breakpoints
    slope = np.array([0, *slope, 0])
    dx_slope        = (dslope[:-1] - dslope[1:]) / (slope[:-1] - slope[1:] + e_guard)
    dx_y_intercept  = (dy_intercept[:-1] - dy_intercept[1:]) / (y_intercept[:-1] - y_intercept[1:] + e_guard)
    dbreakpoints    = (dx_slope - dx_y_intercept) * breakpoints

    check = dbreakpoints[:-1] 

    # dbreakpoints = limiter(dbreakpoints, 1)

    # Update parameters
    slope       += dslope
    y_intercept += dy_intercept
    breakpoints += dbreakpoints
    lr          *= np.exp(-e_lr)

    slope = slope[1:-1]

    breakpoints.sort()

    # print(dbreakpoints)
    # print(dslope)
    # print(dy_intercept)
    # print()
    # print(breakpoints)
    # print(slope)
    # print(y_intercept)

    # print(min(abs(dy_hat)), max(abs(dy_hat)))

    # print("\r")
    if epoch == epochs:
        break

# Calculate the Piecewise linear approximation
y_hat = function_hat(x)
best_slope = np.array([0, *best_slope, 0])

# Calculate the error of each point
dy = y - y_hat

# Calculate the Mean square error
err = np.sqrt(np.mean(dy**2))

print("Total Epochs : ", epoch)
print("Best Epoch   : ", best_epoch)
print('Error : ', best_err)
print('Piecewise Linear Function :')
for i in range(num_line_segments):
    if i == 0:
        print(f'\tf_{i}(x) = {best_slope[i]} x + {best_y_intercept[i]}, \t x < {best_breakpoints[i]}')
    elif i == num_line_segments-1:
        print(f'\tf_{i}(x) = {best_slope[i]} x + {best_y_intercept[i]}, \t x >= {best_breakpoints[i-1]}')
    else :
        print(f'\tf_{i}(x) = {best_slope[i]} x + {best_y_intercept[i]}, \t {best_breakpoints[i-1]} < x <= {best_breakpoints[i]}')

print('\n')
print(*best_breakpoints)
print(*best_slope)
print(*best_y_intercept)

