# matrix_to_10bit.py
# 将任意二维矩阵转换为 10 位补码二进制形式

# def to_10bit_binary(n: int) -> str:
#     if n >= 0:
#         return "0" + format(n, '09b')[-9:]
#     else:
#         return "1" + format(abs(n), '09b')[-9:]
def to_10bit_binary(n: int) -> str:
    return format(n & 0x3FF, '010b')
    
def convert_matrix(infile: str, outfile: str):
    matrix = []

    # 读取矩阵
    with open(infile, "r", encoding="utf-8") as f:
        for line in f:
            if line.strip():  # 跳过空行
                row = [int(x) for x in line.strip().split()]
                matrix.append(row)

    # 转换
    binary_matrix = [[to_10bit_binary(x) for x in row] for row in matrix]

    # 写出
    with open(outfile, "w", encoding="utf-8") as f:
        for row in binary_matrix:
            f.write("".join(row) + ",\n")

    print(f"✅ 转换完成，结果已保存到 {outfile}")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Convert integer matrix to 10-bit binary matrix.")
    parser.add_argument("infile", help="输入矩阵文件路径 (txt)")
    parser.add_argument("outfile", help="输出矩阵文件路径 (txt)")
    args = parser.parse_args()

    convert_matrix(args.infile, args.outfile)

