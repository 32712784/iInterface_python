#!/usr/bin/env bash
# 获取Jenkins传入的Proxy参数。执行方式sh auto_stress_test.sh -a true，其中true可以通过Jenkins自定义变量传入
while getopts ":a:" opt
do
    case $opt in
        a)
        echo "参数Proxy的值$OPTARG"
        export proxy=$OPTARG
        ;;
        ?)
        echo "未知参数"
        ;;
    esac
done

# 压测脚本模板中设定的压测时间应为60秒
export jmx_template="iInterface"
export suffix=".jmx"
export jmx_template_filename="${jmx_template}${suffix}"
export os_type=`uname`

# 需要在系统变量中定义jmeter根目录的位置，如下
export jmeter_path="D:\apache-jmeter-5.4.1"

echo "自动化压测开始"

# 压测并发数列表
thread_number_array=(10 20 30)
for num in "${thread_number_array[@]}"
do
    # 生成对应压测线程的jmx文件
    export jmx_filename="${jmx_template}_${num}${suffix}"
    export jtl_filename="test_${num}.jtl"
    export web_report_path_name="web_${num}"

    rm -f ${jmx_filename} ${jtl_filename}
    rm -rf ${web_report_path_name}

    cp ${jmx_template_filename} ${jmx_filename}
    echo "生成jmx压测脚本 ${jmx_filename}"

    if [[ "${os_type}" == "Darwin" ]]; then
        sed -i "" "s/thread_num/${num}/g" ${jmx_filename}
    else
        sed -i "s/thread_num/${num}/g" ${jmx_filename}
    fi

    # Jenkins中加入代理参数，根据参数决定是否生成带代理的脚本
    if [[ "$proxy" == "true" ]]; then
        echo "${jmx_filename} 正在生成带proxy的jmx脚本"
        sed -i "s/<\/HTTPSamplerProxy>/  <stringProp name=\"HTTPSampler.proxyHost\">localhost<\/stringProp>\n          <stringProp name=\"HTTPSampler.proxyPort\">8888<\/stringProp>\n        <\/HTTPSamplerProxy>/g" ${jmx_filename}
    fi

    # JMeter 静默压测
    ${jmeter_path}/bin/jmeter -n -t ${jmx_filename} -l ${jtl_filename}

    # 生成Web压测报告
    ${jmeter_path}/bin/jmeter -g ${jtl_filename} -e -o ${web_report_path_name}

    # 清除脚本
    rm -f ${jmx_filename} ${jtl_filename}
done
echo "自动化压测全部结束"

