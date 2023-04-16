# This is DM Homework 1 by Kejie Jack He

# Dependencies
from assign1_prototype import correlation_matrix
import numpy
from numpy.lib.index_tricks import mgrid
import pandas
import matplotlib


class grid_tools:

    # The initialization function
    def __init__(self, grid) -> None:
        # The original grid
        self.grid = numpy.array(grid)
        # The transposed grid
        self.grid_t = self.grid.transpose()
        # n for rownum(x_1...x_n) and d for dimensions (A_1...A_d)
        self.n = self.grid.shape[0]
        self.d = self.grid.shape[1]

    # The mean vector miu = (Dt * 1_vector) / n
    def get_mean_vector(self, optional_grid: numpy = None) -> numpy:
        if optional_grid is None:
            # Return if calculated
            if hasattr(self, '__mean_vector'):
                return self.__mean_vector
            # Calculate otherwise
            one_vector = numpy.ones(self.n)
            self.__mean_vector = numpy.divide(
                numpy.matmul(self.grid_t, one_vector), self.n)
            return self.__mean_vector
        else:
            one_vector = numpy.ones(optional_grid.shape[0])
            return numpy.divide(
                numpy.matmul(optional_grid.transpose(), one_vector), optional_grid.shape[0])

    # The total variance var(D)

    def get_total_variance(self) -> numpy:
        # Return if calculated
        if hasattr(self, '__total_variance'):
            return self.__total_variance
        # Calculate otherwise
        result = 0
        for row in self.grid:
            diff = numpy.subtract(row, self.get_mean_vector())
            result += numpy.matmul(diff, diff.transpose())
        result /= (self.n)
        self.__total_variance = result
        return self.__total_variance

    # Return the centered grid using the mean vector
    # D_bar = D - 1_vector dot mean_vector.transpose()
    def get_centered_grid(self, optional_grid: numpy = None) -> numpy:
        if optional_grid is None:
            # Return if calculated
            if hasattr(self, '__centered_grid'):
                return self.__centered_grid
            # Calculate otherwise
            one_vector = numpy.ones([self.n, 1])
            # One vector nx1
            mean_vec = numpy.array([self.get_mean_vector()])
            # Mean vector 1xd
            mean_matrix = numpy.matmul(one_vector, mean_vec)
            self.__centered_grid = numpy.subtract(self.grid, mean_matrix)
            return self.__centered_grid
        else:
            one_vector = numpy.ones([optional_grid.shape[0], 1])
            # One vector nx1
            mean_vec = numpy.array([self.get_mean_vector(optional_grid)])
            # Mean vector 1xd
            mean_matrix = numpy.matmul(one_vector, mean_vec)
            return numpy.subtract(optional_grid, mean_matrix)

    # The inner product form of covariance matrix

    def get_covariance_matrix_inner_product_form(self) -> numpy:
        # Return if calculated
        if hasattr(self, '__covariance_matrix_inner_product_form'):
            return self.__covariance_matrix_inner_product_form
        # Calculate otherwise
        result = numpy.divide(numpy.matmul(
            self.get_centered_grid().T, self.get_centered_grid()), self.n)
        self.__covariance_matrix_inner_product_form = result
        return self.__covariance_matrix_inner_product_form

    # The outer product form of covariance matrix
    def get_covariance_matrix_outer_product_form(self) -> numpy:
        # Return if calculated
        if hasattr(self, '__covariance_matrix_outer_product_form'):
            return self.__covariance_matrix_outer_product_form
        # Calculate otherwise
        result_grid = numpy.zeros([self.d, self.d])
        for row in self.get_centered_grid():
            this_row = numpy.array([row])
            this_layer = numpy.matmul(this_row.T, this_row)
            result_grid = numpy.add(result_grid, this_layer)
        self.__covariance_matrix_outer_product_form = numpy.divide(
            result_grid, self.n)
        return self.__covariance_matrix_outer_product_form

    # Correlation matrix as pairwise cosines
    def get_correlation_matrix(self) -> numpy:
        if hasattr(self, '__correlation_matrix'):
            return self.__correlation_matrix

        centered_grid = self.get_centered_grid(self.grid_t)
        result_matrix = numpy.zeros([self.d, self.d])

        most_correlated = None
        max_correlation = -1
        most_anti_correlated = None
        min_correlation = 1
        most_unrelated = None
        min_correlation_difference = 2

        for i in range(centered_grid.shape[0]):
            for j in range(centered_grid.shape[0]):
                v_1 = numpy.divide(
                    centered_grid[i], numpy.linalg.norm(centered_grid[i]))
                v_2 = numpy.divide(
                    centered_grid[j], numpy.linalg.norm(centered_grid[j]))
                this_result = numpy.matmul(v_1.transpose(), v_2)
                result_matrix[i][j] = this_result

                if this_result > max_correlation and i != j:
                    max_correlation = this_result
                    most_correlated = [
                        centered_grid[i], centered_grid[j], i, j]
                if this_result < min_correlation and i != j:
                    min_correlation = this_result
                    most_anti_correlated = [
                        centered_grid[i], centered_grid[j], i, j]
                if abs(this_result) < min_correlation_difference and i != j:
                    min_correlation_difference = abs(this_result)
                    most_unrelated = [centered_grid[i], centered_grid[j], i, j]

        self.__most_correlated = most_correlated
        self.__most_anti_correlated = most_anti_correlated
        self.__most_unrelated = most_unrelated
        self.__correlation_matrix = result_matrix
        return self.__correlation_matrix

    def get_most_correlated(self):
        if not hasattr(self, "correlation_matrix"):
            self.get_correlation_matrix()
        return self.__most_correlated

    def get_most_anti_correlated(self):
        if not hasattr(self, "correlation_matrix"):
            self.get_correlation_matrix()
        return self.__most_anti_correlated

    def get_most_unrelated(self):
        if not hasattr(self, "correlation_matrix"):
            self.get_correlation_matrix()
        return self.__most_unrelated

    def get_dominant_eigenvector_power_iteration(self, tolerance=0.000001):
        # Generate a random vector
        previous_vector = numpy.random.rand(self.d, 1)
        previous_vector = numpy.divide(
            previous_vector, numpy.linalg.norm(previous_vector))
        while True:
            current_vector = numpy.matmul(self.get_covariance_matrix_inner_product_form(), previous_vector)
            current_vector = numpy.divide(
                current_vector, numpy.linalg.norm(current_vector))
            # Check difference
            diff = numpy.linalg.norm(numpy.subtract(
                current_vector, previous_vector))
            if diff < tolerance:
                break
            previous_vector = current_vector
        return current_vector


if __name__ == "__main__":
    # Read the form
    Original_form = pandas.read_csv('energydata_complete.csv')
    # Remove unnecessary columns
    Original_form = Original_form.iloc[:, 1:-1]
    form = Original_form.to_numpy()

    # Create the matrix_tool
    my_grid = grid_tools(form)

    # Part 1
    print("MEAN_VECTOR -----------------------------------------------------")
    print(my_grid.get_mean_vector())
    print("TOTAL_VARIANCE --------------------------------------------------")
    print(my_grid.get_total_variance())
    print("COVARIANCE_MATRIX_INNER -----------------------------------------")
    print(my_grid.get_covariance_matrix_inner_product_form())
    print("COVARIANCE_MATRIX_OUTER -----------------------------------------")
    print(my_grid.get_covariance_matrix_outer_product_form())
    print("CORRELATION_MATRIX ----------------------------------------------")
    print(my_grid.get_correlation_matrix())

    # Part 2: Dominant Eigen Vector
    print("DOMINANT_EIGENVECTOR --------------------------------------------")
    print(my_grid.get_dominant_eigenvector_power_iteration())
