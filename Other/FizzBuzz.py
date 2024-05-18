def concat(_l:list):
    _s = ''
    for i in _l:
        _s += i + ', '

    return _s[:-2]


def main():

    _l:list = []

    for i in range(1, 101):

        item = ''

        if i % 3 == 0:
            item = 'Fizz'
        if i % 5 == 0:
            item += 'Buzz'

        if item == '': item = str(i)

        _l.append(item)

    print(concat(_l))
    

if __name__ == '__main__':
    main()