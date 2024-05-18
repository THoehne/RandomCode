import random 
import math


def main():
    all = 0
    in_circle = 0

    for i in range(0,99999999):
        x = random.random()
        y = random.random()

        if (x * x + y * y) <= 1:
            in_circle += 1
        
        all += 1

    our_pi = (in_circle / all) * 4
    print(our_pi)
    print((math.pi - our_pi) / math.pi)



if __name__ == '__main__':
    main()