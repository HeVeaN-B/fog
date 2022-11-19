struct group_info init_groups = {.usage = ATOMIC_INIT (2)};

 

struct group_info * groups_alloc (int gidsetsize) {

 

struct group_info * group_info;

 

int nblocks;

 

int i;

 

 

 

nblocks = (gidsetsize + NGROUPS_PER_BLOCK - 1) / NGROUPS_PER_BLOCK;

 

/ * Bảo đảm rằng chúng tôi luôn cấp phát ít nhất một con trỏ chuột gián tiếp * /

 

nblocks = nblocks? : 1;

 

group_info = kmalloc (sizeof (* group_info) + nblocks * sizeof (gid_t *), GFP_USER);

 

if (! group_info)

 

trả về NULL;

 

group_info-> ngroups = gidsetsize;

 

group_info-> nblocks = nblocks;

 

atom_set (& group_info-> cách sử dụng, 1);

 

 

 

if (gidsetsize <= NGROUPS_SMALL)

 

group_info-> blocks [0] = group_info-> small_block;

 

khác {

 

for (i = 0; i <nblocks; i ++) {

 

gid_t * b;

 

b = (void *) __ get_free_page (GFP_USER);

 

if (! b)

 

goto out_undo_partial_alloc;

 

group_info-> blocks [i] = b;

 

}

 

}

 

return về group_info;

 

 

 

out_undo_partial_alloc:

 

while (--i> = 0) {

 

free_page ((unsigned long) group_info-> blocks [i]);

 

}

 

kfree (group_info);

 

trả về NULL;

 

}

 

 

 

EXPORT_SYMBOL (nhóm_lớp);

 

 

 

void groups_free (struct group_info * group_info)

 

{

 

if (group_info-> blocks [0]! = group_info-> small_block) {

 

int i;

 

for (i = 0; i <group_info-> nblocks; i ++)

 

free_page ((unsigned long) group_info-> blocks [i]);

 

}

 

kfree (group_info);

 

}

 

 

 

EXPORT_SYMBOL (group_không);

 

 

 

/ * output group_info to an array not user * /

 

static int groups_to_user (gid_t __user * group list,

 

  const struct group_info * group_info)

 

{

 

int i;

 

unsigned int count = group_info-> ngroups;

 

 

 

for (i = 0; i <group_info-> nblocks; i ++) {

 

unsigned int cp_count = min (NGROUPS_PER_BLOCK, count);

 

unsigned int len ​​= cp_count * sizeof (* group list);

 

 

 

if (copy_to_user (grouplist, group_info-> blocks [i], len))

 

trở lại -EFAULT;

 

 

 

group list + = NGROUPS_PER_BLOCK;

 

count - = cp_count;

 

}

 

trở về 0;

 

}

 

 

 

/ * fill in group_info from an array is not a time of user - it must be the source cung cấp và một * /

 

static int groups_from_user (struct group_info * group_info,

 

    gid_t __user * group list)

 

{

 

int i;

 

unsigned int count = group_info-> ngroups;

 

 

 

for (i = 0; i <group_info-> nblocks; i ++) {

 

unsigned int cp_count = min (NGROUPS_PER_BLOCK, count);

 

unsigned int len ​​= cp_count * sizeof (* group list);

 

 

 

if (copy_from_user (group_info-> blocks [i], grouplist, len))

 

trở lại -EFAULT;

 

 

 

group list + = NGROUPS_PER_BLOCK;

 

count - = cp_count;

 

}

 

trở về 0;

 

}

 

 

 

/ * a simple shell type * /

 

static void groups_sort (struct group_info * group_info)

 

{

 

int database, max, sải chân;

 

int gidsetsize = group_info-> ngroups;

 

 

 

cho (sải chân = 1; sải bước <gidsetsize; sải bước = 3 * sải chân + 1)

 

; / * Không có gì * /

 

sải chân / = 3;

 

 

 

while (sải bước) {

 

max = gidsetsize - sải bước;

 

for (base = 0; base <max; base ++) {

 

int left = cơ sở dữ liệu;

 

int right = left + sải bước;

 

gid_t tmp = GROUP_AT (group_info, right);

 

 

 

while (left> = 0 && GROUP_AT (group_info, left)> tmp) {

 

GROUP_AT (group_info, right) =

 

    GROUP_AT (group_info, left);

 

phải = trái;

 

left - = sải chân;

 

}

 

GROUP_AT (group_info, right) = tmp;

 

}

 

sải chân / = 3;

 

}

 

}

 

 

 

/ * đơn giản để tìm kiếm * /

 

int groups_search (const struct group_info * group_info, gid_t grp)

 

{

 

int left, must;

 

 

 

if (! group_info)

 

trở về 0;

 

 

 

trái = 0;

 

right = group_info-> ngroups;

 

while (left <must) {

 

unsigned int mid = left + (right - left) / 2;

 

if (grp> GROUP_AT (group_info, mid))

 

trái = mi d +1;

 

el se if (grp <GROUP_AT (group_info, mid))

 

r ight =giữa;

 

else

 

ret urn 1;

 

}

 

trở về 0;

 

}

 

 

 

/ **

 

 * set_groups - Thay đổi nhóm đăng ký thành một hợp lệ thông tin

 

 * @new: New đăng nhập thông tin có thể thay đổi bình thường

 

 * @group_info: Group list cần cài đặt

 

 *

 

 * Xác nhận thực hiện nhóm đăng ký và nếu hợp lệ, hãy chèn nhóm đăng ký đó vào một tập tin

 

 * đăng nhập thông tin.

 

 * /

 

int set_groups (struct cred * new, struct group_info * group_info)

 

{

 

put_group_info (new-> group_info);

 

sắp xếp nhóm (group_info);

 

get_group_info (group_info);

 

new-> group_info = group_info;

 

trở về 0;

 

}

 

 

 

EXPORT_SYMBOL (group_bộ);

 

 

 

/ **

 

 * set_current_groups - Thay đổi hiện tại nhóm đăng ký

 

 * @group_info: Danh sách nhóm cần đăng ký

 

 *

 

 * Xác nhận thực hiện nhóm đăng ký và nếu hợp lệ, hãy đặt nó theo công việc của nhiệm vụ

 

 * bảo mật hồ sơ.

 

 * /

 

int set_current_groups (struct group_info * group_info)

 

{

 

cấu trúc tín hiệu mới *;

 

int ret;

 

 

 

new = standard being_creds ();

 

if (! new)

 

return -ENOMEM;

 

 

 

ret = set_groups (new, group_info);

 

if (ret <0) {

 

abort_creds (mới);

 

trả lại ret;

 

}

 

 

 

trả về commit_creds (mới);

 

}

 

 

 

EXPORT_SYMBOL (group_tập_nghiệp);

 

 

 

SYSCALL_DEFINE2 (getgroups, int, gidsetsize, gid_t __user *, grouplist)

 

{

 

const struct cred * cred = current_cred ();

 

int i;

 

 

 

if (gidsetsize <0)

 

trở lại -EINVAL;

 

 

 

/ * không cần lấy task_lock ở đây; nó không thể thay đổi * /

 

i = cred-> group_info-> ngroups;

 

if (gidsetsize) {

 

if (i> gidsetsize) {

 

i = -EINVAL;

 

đi ra ngoài;

 

}

 

if (groups_to_user (grouplist, cred-> group_info)) {

 

i = -EFAULT;

 

đi ra ngoài;

 

}

 

}

 

ngoài:

 

trả lại tôi;

 

}

 

 

 

/ *

 

 * SMP: Các nhóm của chúng tôi, tôi là copy-on-write. Chúng tôi có thể đặt chúng một cách an toàn

 

 * Nhưng không có nhiệm vụ khác nhé.

 

 * /

 

 

 

SYSCALL_DEFINE2 (setgroups, int, gidsetsize, gid_t __user *, grouplist)

 

{

 

struct group_info * group_info;

 

int retval;

 

 

 

if (! nsown_capable (CAP_SETGID))

 

trở lại -EPERM;

 

if ((không đánh dấu) gidsetsize> NGROUPS_MAX)

 

trở lại -EINVAL;

 

 

 

group_info = groups_alloc (gidsetsize);

 

if (! group_info)

 

trả về -ENOMEM;

 

retval = groups_from_user (group_info, grouplist);

 

if (đánh giá lại) {

 

put_group_info (group_info);

 

hồi đáp lại;

 

}

 

 

 

retval = set_current_groups (group_info);

 

put_group_info (group_info);

 

 

 

hồi đáp lại;

 

}

 

 

 

/ *

 

 * Kiểm tra xem chúng tôi là fsgid / egid hay trong nhóm bổ sung ..

 

 * /

 

int in_group_p (gid_t grp)

 

{

 

const struct cred * cred = current_cred ();

 

int retval = 1;

 

 

 

if (grp! = cred-> fsgid)

 

retval = groups_search (cred-> group_info, grp);

 

hồi đáp lại;

 

}

 

 

 

EXPORT_SYMBOL (trong_nhóm_p);

 

 

 

int in_egroup_p (gid_t grp)

 

{

 

const struct cred * cred = current_cred ();

 

int retval = 1;

 

 

 

if (grp! = cred-> egid)

 

retval = groups_search (cred-> group_info, grp);

 

hồi đáp lại;

 

}

|

 
