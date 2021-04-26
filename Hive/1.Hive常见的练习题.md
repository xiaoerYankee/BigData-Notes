#### Hive常见的练习题

##### 1. 测试数据

```sql
-- student
s_id s_name s_birth s_sex
01 赵雷 1990-01-01 男
02 钱电 1990-12-21 男
03 孙风 1990-05-20 男
04 李云 1990-08-06 男
05 周梅 1991-12-01 女
06 吴兰 1992-03-01 女
07 郑竹 1989-07-01 女
08 王菊 1990-01-20 女

-- course
c_id c_course t_id
01	语文	02
02	数学	01
03	英语	03

-- teacher
t_id t_name
01	张三
02	李四
03	王五

-- score
s_id c_id s_score
01	01	80
01	02	90
01	03	99
02	01	70
02	02	60
02	03	80
03	01	80
03	02	80
03	03	80
04	01	50
04	02	30
04	03	20
05	01	76
05	02	87
06	01	31
06	03	34
07	02	89
07	03	98
```

##### 2. 建表语句

```sql
-- student
create table if not exists student (
    s_id int,
    s_name string,
    s_birth string,
    s_sex string
)
row format delimited
fields terminated by ' ';
-- 将 student 文件从本地加载到 hive 数据库下
load data local inpath '/home/hadoop/hiveTable/student' into table student;

-- course
create table if not exists course (
    c_id int,
    c_course string,
    t_id int
)
row format delimited
fields terminated by '\t';
-- 将 course 文件从 HDFS 中加载到 hive 数据库下
load data inpath '/inputData/hiveTable/course' into table course;

-- teacher
create table if not exists teacher (
    t_id int,
    t_name string
)
row format delimited
fields terminated by '\t';
-- 将 teacher 文件从 HDFS 中加载到 hive 数据库下
load data inpath '/inputData/hiveTable/teacher' into table teacher;

-- score
create table if not exists score (
    s_id int,
    c_id int,
    s_score int
)
row format delimited
fields terminated by '\t';
-- 将 score 文件从本地加载到 hive 数据库下
load data local inpath '/home/hadoop/hiveTable/score' into table score;
```

##### 3. 练习题

```sql
-- 查询“01”课程比“02”课程成绩高的学生的信息及课程分数
select s.s_id, s.s_name, s.s_birth, s.s_sex, s1.s_score, s2.s_score
from (select s_id, s_score from score where c_id = 01) s1
join (select s_id, s_score from score where c_id = 02) s2
on s1.s_id = s2.s_id
left join student s on s.s_id = s1.s_id
where s1.s_score > s2.s_score;

-- 查询“01”课程比“02”课程成绩低的学生的信息及课程分数
select s.s_id, s.s_name, s.s_birth, s.s_sex, s1.s_score, s2.s_score
from (select s_id, s_score from score where c_id = 01) s1
join (select s_id, s_score from score where c_id = 02) s2 on s1.s_id = s2.s_id
left join student s
on s.s_id = s1.s_id
where s1.s_score < s2.s_score;

-- 查询平均成绩大于等于60分的同学的学生编号、学生姓名和平均成绩
select sc.s_id, s.s_name, avg(sc.s_score)
from score sc
left join student s on s.s_id = sc.s_id
group by sc.s_id, s.s_name
having avg(sc.s_score) >= 60;

-- 查询平均成绩小于60分的同学的学生编号、学生姓名和平均成绩（包括有成绩的和无成绩的）
select t.s_id, t.s_name, t.avgscore
from (select s.s_id, s.s_name, case when avg(sc.s_score) is null then 0 else avg(sc.s_score) end avgscore
from student s
left join score sc on s.s_id = sc.s_id
group by s.s_id, s.s_name) t
where t.avgscore < 60;

-- 查询所有同学的学生编号、学生姓名、选课总数、所有课程的总成绩
select s.s_id, s.s_name, count(sc.s_score) countscore, sum(sc.s_score) total
from student s
left join score sc on s.s_id = sc.s_id
group by s.s_id, s.s_name;

-- 查询"李"姓老师的数量
select count(1) countteacher
from teacher t
where t.t_name like '李%';

-- 查询学过"张三"老师授课的同学的信息
select s.s_id, s.s_name, s.s_birth, s.s_sex
from student s
join score sc on s.s_id = sc.s_id
join course c on sc.c_id = c.c_id
join teacher t on t.t_id = c.t_id
where t.t_name = '张三';

-- 查询没学过"张三"老师授课的同学的信息
-- 使用 not in 查询6个 job
select s1.s_id, s1.s_name, s1.s_birth, s1.s_sex
from student s1
where s_id not in (select s.s_id
from student s
join score sc on s.s_id = sc.s_id
join course c on sc.c_id = c.c_id
join teacher t on t.t_id = c.t_id
where t.t_name = '张三');

-- 优化：使用 not exists 代替 not in，3个 job
select s1.s_id, s1.s_name, s1.s_birth, s1.s_sex
from student s1
where not exists (select s.s_id
from student s
join score sc on s.s_id = sc.s_id
join course c on sc.c_id = c.c_id
join teacher t on t.t_id = c.t_id
where t.t_name = '张三' and s.s_id = s1.s_id);

-- 查询学过编号为"01"并且也学过编号为"02"的课程的同学的信息
select s.s_id, s.s_name, s.s_birth, s.s_sex
from (select s_id from score where c_id = '01') sc1
join (select s_id from score where c_id = '02') sc2 on sc1.s_id = sc2.s_id
left join student s on s.s_id = sc1.s_id;

-- 查询学过编号为"01"但是没有学过编号为"02"的课程的同学的信息
select s.s_id, s.s_name, s.s_birth, s.s_sex
from (select s_id from score where c_id = '01') sc1
left join (select s_id from score where c_id = '02') sc2 on sc1.s_id = sc2.s_id
left join student s on s.s_id = sc1.s_id
where sc2.s_id is null;

-- 查询没有学全所有课程的同学的信息
select s.s_id, max(s.s_name), max(s.s_birth), max(s.s_sex)
from student s
join course c
left join score sc on sc.s_id = s.s_id and c.c_id = sc.c_id
where sc.s_score is null
group by s.s_id;

-- 查询至少有一门课与学号为"01"的同学所学相同的同学的信息
select s.s_id, max(s.s_name), max(s.s_birth), max(s.s_sex)
from student s
join score sc on sc.s_id = s.s_id
where s.s_id <> '01' and exists (
    select c_id from score where s_id = '01')
group by s.s_id;

select distinct s.s_id, s.s_name, s.s_birth, s.s_sex
from student s
join score sc on sc.s_id = s.s_id
where s.s_id <> '01' and sc.c_id in (
    select c_id from score where s_id = '01');
    
-- 查询和"01"号的同学学习的课程完全相同的其他同学的信息
select s.s_id, s.s_name, s.s_birth, s.s_sex
from student s
join (select s_id, concat_ws('-', collect_set(cast(c_id as string))) course_id
from score
where s_id <> '01'
group by s_id) t1 on t1.s_id = s.s_id
join (select s_id, concat_ws('-', collect_set(cast(c_id as string))) course_id
from score
where s_id = '01'
group by s_id) t2 on t2.course_id = t1.course_id;

-- 查询没学过"张三"老师讲授的任一门课程的学生姓名
select s.s_name
from student s
where not exists (
select sc.s_id
from teacher t, course c, score sc
where t.t_id = c.t_id and t.t_name = '张三' and sc.c_id = c.c_id and sc.s_id = s.s_id);

-- 查询两门及其以上不及格课程的同学的学号，姓名及其平均成绩
select s.s_id, s.s_name, t.avgScore
from student s
join (select s_id, count(s_id) countNum, avg(s_score) avgScore
from score
where s_score < 60
group by s_id) t on s.s_id = t.s_id;

-- 检索"01"课程分数小于60，按分数降序排列的学生信息
select t.s_id, t.s_name, t.s_birth, t.s_sex
from (select s.s_id, s.s_name, s.s_birth, s.s_sex, sc.s_score
from student s
join score sc on sc.s_id = s.s_id
where sc.c_id = '01' and sc.s_score < 60
order by sc.s_score desc) t;

-- 按平均成绩从高到低显示所有学生的所有课程的成绩以及平均成绩
select s.s_id, max(s.s_name) s_name,
sum(case sc.c_id when '01' then sc.s_score else 0 end) `语文`,
max(case sc.c_id when '02' then sc.s_score else 0 end) `数学`,
sum(if(sc.c_id='03', sc.s_score, 0)) `英语`,
if(avg(sc.s_score) is null, 0, avg(sc.s_score)) avgScore
from student s
left join score sc on sc.s_id = s.s_id 
group by s.s_id
order by avgScore desc;

-- 查询各科成绩最高分、最低分和平均分：以如下形式显示：课程ID，课程name，最高分，最低分，平均分，及格率，中等率，优良率，优秀率
select sc.c_id, c.c_course, max(sc.s_score) maxScore, min(sc.s_score) minScore, round(avg(sc.s_score), 2) avgScore, round(avg(sc.`及格`), 2) `及格率`, round(avg(sc.`中等`), 2) `中等率`, round(avg(sc.`优良`), 2) `优良率`, round(avg(sc.`优秀`), 2) `优秀率`
from (select s_id, c_id, s_score,
case when s_score >= 60 then 1 else 0 end as `及格`,
case when s_score >= 70 and s_score < 80 then 1 else 0 end as `中等`,
case when s_score >= 80 and s_score < 90 then 1 else 0 end as `优良`,
case when s_score >= 90 then 1 else 0 end as `优秀`
from score) sc
left join course c on c.c_id = sc.c_id
group by sc.c_id, c.c_course;

-- 按各科成绩进行排序，并显示排名:– row_number() over()分组排序功能
select s_id, c_id, s_score,
row_number() over(distribute by c_id sort by s_score desc) rowNum
from score;

-- 查询学生的总成绩并进行排名
select s.s_id, s.s_name, sum(s_score) sumScore
from score sc
join student s on s.s_id = sc.s_id
group by s.s_id,s.s_name
order by sumScore desc;

-- 查询不同老师所教不同课程平均分从高到低显示
select c.t_id, sc.c_id, round(avg(sc.s_score), 2) avgScore
from score sc
join course c on sc.c_id = c.c_id
group by c.t_id, sc.c_id
order by c.t_id, avgScore desc;

-- 查询所有课程的成绩第2名到第3名的学生信息及该课程成绩
select s.s_id, s.s_name, s.s_birth, s.s_sex, sc.s_score
from (select s_id, c_id, s_score,
row_number() over(distribute by c_id sort by s_score desc) rowNum
from score) sc
left join student s on s.s_id = sc.s_id
where sc.rowNum between 2 and 3;

-- 统计各科成绩各分数段人数：课程编号,课程名称,[100-85],[85-70],[70-60],[0-60]及所占百分比
select sc.c_id, c.c_course,
round(sum(case when sc.s_score >= 85 then 1 else 0 end)/count(1), 2) 85Score,
round(sum(case when sc.s_score >= 70 and sc.s_score < 85 then 1 else 0 end)/count(1), 2) 70Score,
round(sum(case when sc.s_score >= 60 and sc.s_score < 70 then 1 else 0 end)/count(1), 2) 60Score,
round(sum(case when sc.s_score < 60 then 1 else 0 end)/count(1), 2) 0Score,
count(1) as totalStu
from score sc
left join course c on c.c_id = sc.c_id
group by sc.c_id, c.c_course;

-- 查询学生平均成绩及其名次
select sc.s_id, sc.avgScore, row_number() over(sort by sc.avgScore desc) rowNum
from (select s_id, round(avg(s_score), 2) avgScore
from score
group by s_id) sc;

-- 查询各科成绩前三名的记录三个语句
select sc.s_id, sc.c_id, sc.s_score, sc.rowNum, sc.rankNum, sc.denseRank
from (select s_id, c_id, s_score,
row_number() over(distribute by c_id sort by s_score desc) as rowNum,
rank() over(distribute by c_id sort by s_score desc) as rankNum,
dense_rank() over(distribute by c_id sort by s_score desc) as denseRank
from score) sc
where sc.rowNum < 4;

-- 查询每门课程被选修的学生数
select c_id, count(1) totalStu
from score
group by c_id;

-- 查询出只有两门课程的全部学生的学号和姓名
select s.s_id, s.s_name
from score sc
left join student s on s.s_id = sc.s_id
group by s.s_id, s.s_name
having count(1) = 2;

-- 查询男生、女生人数
select s_sex, count(1) totalSex
from student
group by s_sex;

-- 查询名字中含有"风"字的学生信息
select s_id, s_name, s_birth, s_sex
from student
where s_name like '%风%';

-- 查询同名同性学生名单，并统计同名人数
select s_name, s_sex, count(1) totalStu
from student
group by s_name, s_sex
having totalStu > 1;

-- 查询1990年出生的学生名单
select s_id, s_name, s_birth, s_sex
from student
where year(s_birth) = '1990';

-- 查询每门课程的平均成绩，结果按平均成绩降序排列，平均成绩相同时，按课程编号升序排列
select sc.c_id, sc.avgScore
from (select c_id, round(avg(s_score), 2) avgScore
from score
group by c_id) sc
order by sc.avgScore desc, sc.c_id asc;

-- 查询平均成绩大于等于85的所有学生的学号、姓名和平均成绩
select s.s_id, s.s_name, avg(sc.s_score) avgScore
from student s
left join score sc on sc.s_id = s.s_id
group by s.s_id, s.s_name
having avg(sc.s_score) >= 85;

-- 查询课程名称为"数学"，且分数低于60的学生姓名和分数
select s.s_name, sc.s_score
from score sc
left join course c on sc.c_id = c.c_id
left join student s on s.s_id = sc.s_id
where c.c_course = '数学' and sc.s_score < 60;

-- 查询所有学生的课程及分数情况
select s.s_id, s.s_name,
sum(case sc.c_id when '01' then sc.s_score else 0 end) `语文`,
sum(case sc.c_id when '02' then sc.s_score else 0 end) `数学`,
sum(if(sc.c_id='03', sc.s_score, 0)) `英语`
from student s
left join score sc on sc.s_id = s.s_id
group by s.s_id, s.s_name;

-- 查询任何一门课程成绩在70分以上的学生姓名、课程名称和分数
select s.s_id, s.s_name, c.c_course, sc.s_score
from student s
left join score sc on sc.s_id = s.s_id
left join course c on sc.c_id = c.c_id
where sc.s_score > 70;

-- 查询课程不及格的学生
select s.s_id, s.s_name, c.c_course, sc.s_score
from score sc
left join student s on s.s_id = sc.s_id
left join course c on c.c_id = sc.c_id
where sc.s_score < 60;

-- 查询课程编号为01且课程成绩在80分以上的学生的学号和姓名
select s.s_id, s.s_name
from score sc
left join student s on s.s_id = sc.s_id
where sc.c_id = '01' and sc.s_score > 80;

-- 求每门课程的学生人数
select sc.c_id, c.c_course, count(1) totalStu
from score sc
left join course c on c.c_id = sc.c_id
group by sc.c_id, c.c_course;

-- 查询选修"张三"老师所授课程的学生中，成绩最高的学生信息及其成绩
select a.s_id, a.s_name, a.s_score
from (select s.s_id, s.s_name, sc.s_score,
dense_rank() over(distribute by sc.c_id sort by sc.s_score desc) denseRank
from score sc
left join student s on s.s_id = sc.s_id
left join course c on c.c_id = sc.c_id
left join teacher t on t.t_id = c.t_id
where t.t_name = '张三') a
where a.denseRank = 1;

-- 查询不同课程成绩相同的学生的学生编号、课程编号、学生成绩
select sc1.s_id, sc1.c_id, sc1.s_score
from score sc1
join score sc2 on sc1.c_id != sc2.c_id
where sc1.s_score = sc2.s_score and sc1.s_id = sc2.s_id
group by sc1.s_id, sc1.c_id, sc1.s_score;

select distinct sc1.s_id, sc1.c_id, sc1.s_score
from score sc1
join score sc2 on sc1.c_id != sc2.c_id
where sc1.s_score = sc2.s_score and sc1.s_id = sc2.s_id;

-- 查询每门课程成绩最好的前三名
select sc.s_id, sc.c_id, sc.s_score, sc.denseNum
from(select s_id, c_id, s_score, dense_rank() over(distribute by c_id sort by s_score desc) as denseNum
from score) sc
where sc.denseNum < 4;

-- 统计每门课程的学生选修人数（超过5人的课程才统计）：要求输出课程号和选修人数，查询结果按人数降序排列，若人数相同，按课程号升序排列
select sc.c_id, count(sc.c_id) countNum
from score sc
group by sc.c_id
having countNum > 5
order by countNum desc, sc.c_id asc;

-- 检索至少选修两门课程的学生学号
select sc.s_id, count(sc.c_id) countNum
from score sc
group by sc.s_id
having countNum >= 2;

-- 查询选修了全部课程的学生信息
select s.s_id, s.s_name
from student s
join course c
left join score sc on sc.c_id = c.c_id and sc.s_id = s.s_id
group by s.s_id, s.s_name
having sum(case when sc.s_score is null then 1 else 0 end) = 0;

-- 查询各学生的年龄(周岁): – 按照出生日期来算，当前月日 < 出生年月的月日则，年龄减一
select s_birth, (year(current_date()) - year(s_birth) - 
(case when month(current_date()) > month(s_birth) then 0 when month(current_date()) = month(s_birth) and day(current_date()) >= day(s_birth) then 0 else 1 end)) age
from student;

-- 查询本周过生日的学生
select s_id, s_name, s_birth, s_sex
from student
where weekofyear(s_birth) = weekofyear(current_date());

-- 查询下周过生日的学生
select s_id, s_name, s_birth, s_sex
from practice.student
where weekofyear(s_birth) = weekofyear(current_date()) + 1;

-- 查询本月过生日的学生
select s_id, s_name, s_birth, s_sex
from practice.student
where month(current_date()) = month(s_birth);

-- 查询12月份过生日的学生
select s_id, s_name, s_birth, s_sex
from practice.student
where month(s_birth) = 12;
```

