with open("APPmsg_input_buffer_0.coe", "w") as f:
    f.write("MEMORY_INITIALIZATION_RADIX=2;\n")
    f.write("MEMORY_INITIALIZATION_VECTOR=\n")

    value = 0       # 当前的6位数
    count = 0       # 计数器
    for j in range(4):
        for i in range(512):
            bin_str = format(value % 64, "06b")

            if i < 511:
                f.write(bin_str)
            else:
                if j<3:
                    f.write(bin_str + ",\n")  # 最后一行用分号
                else:
                    f.write(bin_str + ";\n")  # 最后一行用分号
            count += 1
            if count == 16:   # 每16次计数完成
                value += 1    # 数据加1
                count = 0     # 计数器清零