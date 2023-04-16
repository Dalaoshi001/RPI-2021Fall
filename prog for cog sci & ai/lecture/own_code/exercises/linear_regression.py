import warnings

import matplotlib as matplotlib

warnings.simplefilter(action='ignore', category=FutureWarning)
warnings.simplefilter(action='ignore', category=UserWarning)

import numpy as np
import pandas as pd
from scipy import stats
import seaborn as sns
import matplotlib.pyplot as plt
# %matplotlib inline

from sklearn.preprocessing import LabelEncoder,OneHotEncoder,StandardScaler,MinMaxScaler
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.metrics import r2_score,mean_squared_error

def rmse(y,yhat):
    return np.sqrt(np.mean((y - yhat)**2))

if __name__ == "__main__":
    np.set_printoptions(suppress=True)
    #exercise 1:
    howell = pd.read_csv("Howell.csv",sep=';')
    adult = howell.query("age > 17")
    X = adult.loc[:,['weight', 'age']].values
    y = adult.height.values
    print(X.shape)
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=1234)
    print(X_train.shape, X_test.shape, y_train.shape, y_test.shape)

    scaler = StandardScaler()
    X_train[:,0:2] = scaler.fit_transform(X_train[:,0:2])
    X_test[:,0:2] = scaler.transform(X_test[:,0:2])
    print(X_train.shape, X_test.shape)

    model = LinearRegression()
    model.fit(X_train, y_train)
    print("Intercept: ", end="")
    print(model.intercept_, end="")
    print(" Coefficients: ", end="")
    print(model.coef_)

    yhat = model.predict(X_test)
    print(yhat.shape)
    print(np.round(model.score(X_test, y_test), 2))
    print(np.round(rmse(y_test, yhat), 2))
    print('#' * 40)
    #exercise 2:
    xlabel, ylabel = 'weight', 'height'
    X = howell.weight.values.reshape(-1, 1)
    y = howell.height.values
    howell['weight2'] = howell.weight ** 2
    howell['weight3'] = howell.weight ** 3
    X3 = howell.loc[:,['weight', 'weight2', 'weight3']]
    print(X3.shape, y.shape)
    X_train, X_test, y_train, y_test = train_test_split(X3, y, test_size=0.2, random_state=1234)
    print(X_train.shape, X_test.shape, y_train.shape, y_test.shape)
    model = LinearRegression()
    model.fit(X_train, y_train)
    yhat = model.predict(X_test)
    print("Intercept: ", end="")
    print(model.intercept_, end="")
    print(" Coefficients: ", end="")
    print(model.coef_)
    print('R-squared: ', end="")
    print(np.round(model.score(X3, y), 2))
    print("RMSE: ", end = "")
    print(np.round(rmse(y_test, yhat), 2))
    print(X_test.iloc[:,0].shape)
    plt.figure()
    plt.scatter(X, y, color = 'red')
    plt.plot(X_test.iloc[:,0], yhat, 'bo')
    plt.title('Predicted Values')
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.show()