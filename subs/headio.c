/************************************************************************/
/*									*/
/*	Routines to access "header" variables.				*/
/*									*/
/*--									*/
/* History:								*/
/*  rjs Dark_ages Original version					*/
/*  rjs 23aug89   Fixed char variable overrun problem, in hdprobe.	*/
/*  rjs 12feb90   Added some comments, to appease PJT.			*/
/*  rjs 21feb90   Corrected a comment.					*/
/*  rjs  7mar90   Added hisopen with status='write'			*/
/*  rjs 27apr90   Fixed bug in hdprobe, which got the lengths of items	*/
/*		  less than ITEM_HDR_SIZE long wrong.			*/
/*  pjt 19mar91   output double prec variables in -20.10g		*/
/*  rjs 26aug92   Corrected hdprsnt declaration, and the value that	*/
/*		  it returns.						*/
/*  rjs 23feb93   Rename a defined parameter only.			*/
/*  rjs 10aug93   Use hexists in hdprsnt.				*/
/*  rjs  6nov94   Change "item handle" to an integer.			*/
/*  rjs 15may96   Fiddles with roundup macro.				*/
/*  pjt 27mar99   make history a static, so nobody can see it :-)	*/
/*  rjs 29apr99   Get hdprobe to check for string buffer overflow.	*/
/*  dpr 11may01   Descriptive error for hisopen_c			*/
/*  pjt 22jun02   MIR4 prototypes and using int8 for long integers	*/
/*  rjs 02jan05   Fix up bug in rdhdl. Tidy.				*/
/*  rjs 26nov05   Better handling of logical values.			*/
/*  rjs 28jun06   Correct doc comment.					*/
/*  rjs 27nov06   Get rdhdd to handle long integers			*/
/*  rjs 01jan07   Extra checks for large integers.			*/
/*  rjs 17mar11   Handle large items and avoid overflow better. 	*/
/*  rjs 14dec11   More robust in hdprobe to non-existent items		*/
/*  mhw 25jun12   Better error reporting using bugv (from carma)        */ 
/************************************************************************/

#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>
#include <limits.h>
#include "miriad.h"
#include "io.h"

#define check(iostat) if(iostat)bugno_c('f',iostat)
#define MAXSIZE 1024
#define MAXLINE 80


static int history[MAXOPEN];

#define Sprintf (void)sprintf
#define Strcpy	(void)strcpy

/************************************************************************/
void hisopen_c(int tno,Const char *status)
/** hisopen -- Open the history file.					*/
/*& pjt 								*/
/*: header-i/o								*/
/*+ FORTRAN call sequence:

	subroutine hisopen(tno,status)
	integer tno
	character status

  This opens the history file, and readies it to be read or written.

  Inputs:
    tno 	The handle of the open data set.
    status	Either "read", "write" or "append".			*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  int iostat;
  haccess_c(tno,&history[tno],"history",status,&iostat);
  if(iostat) {bug_c('e',"Problem with history item");};
  check(iostat);
}
/************************************************************************/
void hiswrite_c(int tno,Const char *text)
/** hiswrite -- Write a line of text to the history file.		*/
/*& pjt 								*/
/*: header-i/o								*/
/*+ FORTRAN call sequence:

	subroutine hiswrite(tno,line)
	integer tno
	character line*(*)

  This writes a text string to the history file associated with an open
  data set.

  Inputs:
    tno 	The handle of the open data set.
    line	The string of text to be written to the history file.	*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  int iostat;
  hwritea_c(history[tno],text,strlen(text)+1,&iostat);		check(iostat);
}
/************************************************************************/
void hisread_c(int tno,char *text,size_t length,int *eof)
/** hisread -- Read a line of text from the history file.		*/
/*& pjt 								*/
/*: header-i/o								*/
/*+ FORTRAN call sequence:

	subroutine hisread(tno,line,eof)
	integer tno
	character line*(*)
	logical eof

  This reads a line of text from the history file.

  Input:
    tno 	The handle of the input data set.
  Output:
    line	The string to receive the read string.
    eof 	This logical variable turns true when the end of the
		history file is reached.				*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  int iostat;
  hreada_c(history[tno],text,length,&iostat);
  if(iostat == 0) *eof = 0;
  else if(iostat == -1) *eof = 1;
  else bugno_c('f',iostat);
}
/************************************************************************/
void hisclose_c(int tno)
/** hisclose -- This closes the history file.				*/
/*& pjt 								*/
/*: header-i/o								*/
/*+ FORTRAN call sequence:

	subroutine hisclose(tno
	integer tno

  This closes the history file associated with a particular data set.
  Input:
    tno 	The handle of the data set.				*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  int iostat;
  hdaccess_c(history[tno],&iostat);				check(iostat);
}
/************************************************************************/
void wrhdr_c(int thandle,Const char *keyword,double value)
/** wrhdr -- Write a real valued header variable.			*/
/*& pjt 								*/
/*: header-i/o								*/
/*+ FORTRAN call sequence:

	subroutine wrhdr(tno,keyword,value)
	integer tno
	character keyword*(*)
	real value

  This writes a real-valued header keyword.
  Input:
    tno 	Handle of the data set.
    keyword	Name of the keyword to write.
    value	The value of the keyword.				*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  int item;
  float temp;
  int iostat,offset;

  temp = value;
  haccess_c(thandle,&item,keyword,"write",&iostat);		check(iostat);
  hwriteb_c(item,real_item,0,ITEM_HDR_SIZE,&iostat);		check(iostat);
  offset = mroundup(ITEM_HDR_SIZE,H_REAL_SIZE);
  hwriter_c(item,&temp,offset,H_REAL_SIZE,&iostat);		check(iostat);
  hdaccess_c(item,&iostat);					check(iostat);
}
/************************************************************************/
void wrhdd_c(int thandle,Const char *keyword,double value)
/** wrhdd -- Write a double precision valued header variable.		*/
/*& mjs 								*/
/*: header-i/o								*/
/*+ FORTRAN call sequence:

	subroutine wrhdd(tno,keyword,value)
	integer tno
	character keyword*(*)
	double precision value

  Write the value of a header variable which has a double precision value.

  Input:
    tno 	The handle of the data set.
    keyword	Name to the keyword.
    value	The double precision value.				*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  int item;
  int iostat,offset;

  haccess_c(thandle,&item,keyword,"write",&iostat);		check(iostat);
  hwriteb_c(item,dble_item,0,ITEM_HDR_SIZE,&iostat);		check(iostat);
  offset = mroundup(ITEM_HDR_SIZE,H_DBLE_SIZE);
  hwrited_c(item,&value,offset,H_DBLE_SIZE,&iostat);		check(iostat);
  hdaccess_c(item,&iostat);					check(iostat);
}
/************************************************************************/
void wrhdi_c(int thandle,Const char *keyword,int value)
/** wrhdi -- Write an integer valued header variable.			*/
/*& mjs 								*/
/*: header-i/o								*/
/*+ FORTRAN call sequence:

	subroutine wrhdi(tno,keyword,value)
	integer tno
	character keyword*(*)
	integer value

  Write an integer valued header variable.

  Input:
    tno 	The handle of the data set.
    keyword	The name of the header variable.
    value	The integer value of the header variable.		*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  int item;
  int iostat,offset;

  haccess_c(thandle,&item,keyword,"write",&iostat);		check(iostat);
  hwriteb_c(item,int_item,0,ITEM_HDR_SIZE,&iostat);		check(iostat);
  offset = mroundup(ITEM_HDR_SIZE,H_INT_SIZE);
  hwritei_c(item,&value,offset,H_INT_SIZE,&iostat);		check(iostat);
  hdaccess_c(item,&iostat);					check(iostat);
}
/************************************************************************/
void wrhdl_c(int thandle,Const char *keyword,int8 value)
/** wrhdl -- Write an integer*8 valued header variable. 		*/
/*& pjt 								*/
/*: header-i/o								*/
/*+ FORTRAN call sequence:

	subroutine wrhdl(tno,keyword,value)
	integer tno
	character keyword*(*)
	integer*8 value

  Write an integer*8 valued header variable. This always will write
  an integer*4 if this is possible.

  Input:
    tno 	The handle of the data set.
    keyword	The name of the header variable.
    value	The integer*8 value of the header variable.		*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  int item;
  int iostat,offset,temp;

/* Always try to write an integer if possible. */

  haccess_c(thandle,&item,keyword,"write",&iostat);		check(iostat);
  if(value > 0x7FFFFFFF || value < 0x80000000){
    hwriteb_c(item,int8_item,0,ITEM_HDR_SIZE,&iostat);		check(iostat);
    offset = mroundup(ITEM_HDR_SIZE,H_INT8_SIZE);
    hwritel_c(item,&value,offset,H_INT8_SIZE,&iostat);		check(iostat);
  }else{
    temp = value;
    hwriteb_c(item,int_item,0,ITEM_HDR_SIZE,&iostat);		check(iostat);
    offset = mroundup(ITEM_HDR_SIZE,H_INT_SIZE);
    hwritei_c(item,&temp,offset,H_INT_SIZE,&iostat);		check(iostat);
  }
  hdaccess_c(item,&iostat);					check(iostat);
}
/************************************************************************/
void wrhdc_c(int thandle,Const char *keyword,Const float *value)
/** wrhdc -- Write a complex-valued header variable.			*/
/*& mjs 								*/
/*: header-i/o								*/
/*+ FORTRAN call sequence:

	subroutine wrhdc(tno,keyword,value)
	integer tno
	character keyword*(*)
	complex value

  Write a complex valued header variable.
  Input:
    tno 	The file handle fo the data set.
    keyword	The name of the header variable.
    value	The complex value of the header variable.		*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  int item;
  int iostat,offset;

  haccess_c(thandle,&item,keyword,"write",&iostat);		check(iostat);
  hwriteb_c(item,cmplx_item,0,ITEM_HDR_SIZE,&iostat);		check(iostat);
  offset = mroundup(ITEM_HDR_SIZE,H_CMPLX_SIZE);
  hwritec_c(item,value,offset,H_CMPLX_SIZE,&iostat);		check(iostat);
  hdaccess_c(item,&iostat);					check(iostat);
}
/************************************************************************/
void wrhda_c(int thandle,Const char *keyword,Const char *value)
/** wrhda -- Write a string-valued header variable.			*/
/*& mjs 								*/
/*: header-i/o								*/
/*+ FORTRAN call sequence:

	subroutine wrhda(tno,keyword,value)
	integer tno
	character keyword*(*)
	character value*(*)

  Write a string valued header variable.

  Input:
    tno 	The file handle of the data set.
    keyword	The name of the header variable.
    value	The value of the header variable.			*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  int item;
  int iostat;

  haccess_c(thandle,&item,keyword,"write",&iostat);		check(iostat);
  hwriteb_c(item,char_item,0,ITEM_HDR_SIZE,&iostat);		check(iostat);
  hwriteb_c(item,(char *)value,ITEM_HDR_SIZE,
	    strlen(value),&iostat);				check(iostat);
  hdaccess_c(item,&iostat);					check(iostat);
}
/************************************************************************/
void rdhdr_c(int thandle,Const char *keyword,float *value,double defval)
/** rdhdr -- Read a real-valued header variable.			*/
/*& mjs 								*/
/*: header-i/o								*/
/*+ FORTRAN call sequence:

	subroutine rdhdr(tno,keyword,value,default)
	integer tno
	character keyword*(*)
	real value,default

  Read a real valued header variable.

  Input:
    tno 	The file handle of the data set.
    keyword	The name of the header variable.
    default	The default value to return, if the header variable
		is not found.
  Output:
    value	The value of the header variable. This will be the default
		value, if the variable is missing from the header.	*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  double dvalue,ddefval;
  ddefval = defval;
  rdhdd_c(thandle,keyword,&dvalue,ddefval);
  *value = dvalue;
}
/************************************************************************/
void rdhdi_c(int thandle,Const char *keyword,int *value,int defval)
/** rdhdi -- Read an integer-valued header variable.			*/
/*& mjs 								*/
/*: header-i/o								*/
/*+ FORTRAN call sequence:

	subroutine rdhdi(tno,keyword,value,default)
	integer tno
	character keyword*(*)
	integer value,default

  Read an integer valued header variable.

  Input:
    tno 	The file handle of the data set.
    keyword	The name of the header variable.
    default	The default value to return, if the header variable
		is not found.
  Output:
    value	The value of the header variable. This will be the default
		value, if the variable is missing from the header.	*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  double dvalue,ddefval;
  ddefval = defval;
  rdhdd_c(thandle,keyword,&dvalue,ddefval);
  if(dvalue > INT_MAX || dvalue < INT_MIN)bug_c('f',"Integer overflow in rdhdi");
  *value = dvalue;
}
/************************************************************************/
void rdhdl_c(int thandle,Const char *keyword,int8 *value,int8 defval)
/** rdhdl -- Read an integer*8-valued header variable.			*/
/*& mjs 								*/
/*: header-i/o								*/
/*+ FORTRAN call sequence:

	subroutine rdhdl(tno,keyword,value,default)
	integer tno
	character keyword*(*)
	integer*8 value,default

  Read an integer valued header variable.

  Input:
    tno 	The file handle of the data set.
    keyword	The name of the header variable.
    default	The default value to return, if the header variable
		is not found.
  Output:
    value	The value of the header variable. This will be the default
		value, if the variable is missing from the header.	*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  int item;
  char s[ITEM_HDR_SIZE];
  int iostat;
  off_t offset,length;
  int itemp;
  int8 ltemp;

/* Firstly assume the variable is missing. Try to get it. If successful
   read it. */

  *value = defval;
  haccess_c(thandle,&item,keyword,"read",&iostat);	if(iostat)return;
  length = hsize_c(item);
  if(length >= 0){

/* Determine the type of the value, and convert it to double precision. */

    hreadb_c(item,s,0,ITEM_HDR_SIZE,&iostat);		check(iostat);
    iostat = 0;
    if(      !memcmp(s,int_item, ITEM_HDR_SIZE)){
      offset = mroundup(ITEM_HDR_SIZE,H_INT_SIZE);
      if(offset + H_INT_SIZE == length){
	hreadi_c(item,&itemp,offset,H_INT_SIZE,&iostat);
	*value = itemp;
      }
    } else if(!memcmp(s,int8_item,ITEM_HDR_SIZE)){
      offset = mroundup(ITEM_HDR_SIZE,H_INT8_SIZE);
      if(offset + H_INT8_SIZE == length){
	hreadl_c(item,&ltemp,offset,H_INT8_SIZE,&iostat);
	*value = ltemp;
      }
    } else {
      bugv_c('f',"rdhdl_c: item %s not an int8 or small enough int4",keyword);
    }
    check(iostat);
  }
  hdaccess_c(item,&iostat);				check(iostat);
}
/************************************************************************/
void rdhdd_c(int thandle,Const char *keyword,double *value,double defval)
/** rdhdd -- Read a double precision-valued header variable.		*/
/*& mjs 								*/
/*: header-i/o								*/
/*+ FORTRAN call sequence:

	subroutine rdhdd(tno,keyword,value,default)
	integer tno
	character keyword*(*)
	double precision value,default

  Read a double precision valued header variable.

  Input:
    tno 	The file handle of the data set.
    keyword	The name of the header variable.
    default	The default value to return, if the header variable
		is not found.
  Output:
    value	The value of the header variable. This will be the default
		value, if the variable is missing from the header.	*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  int item;
  char s[ITEM_HDR_SIZE];
  int iostat,itemp;
  off_t offset,length;
  float rtemp;
  int8 ltemp;

/* Firstly assume the variable is missing. Try to get it. If successful
   read it. */

  *value = defval;
  haccess_c(thandle,&item,keyword,"read",&iostat);	if(iostat)return;
  length = hsize_c(item);
  if(length >= 0){

/* Determine the type of the value, and convert it to double precision. */

    hreadb_c(item,s,0,ITEM_HDR_SIZE,&iostat);		check(iostat);
    iostat = 0;
    if(      !memcmp(s,int_item, ITEM_HDR_SIZE)){
      offset = mroundup(ITEM_HDR_SIZE,H_INT_SIZE);
      if(offset + H_INT_SIZE == length){
	hreadi_c(item,&itemp,offset,H_INT_SIZE,&iostat);
	*value = itemp;
      }
    } else if(!memcmp(s,int8_item,ITEM_HDR_SIZE)){
      offset = mroundup(ITEM_HDR_SIZE,H_INT8_SIZE);
      if(offset + H_INT8_SIZE == length){
	hreadl_c(item,&ltemp,offset,H_INT8_SIZE,&iostat);
	*value = ltemp;
      }
    } else if(!memcmp(s,real_item,ITEM_HDR_SIZE)){
      offset = mroundup(ITEM_HDR_SIZE,H_REAL_SIZE);
      if(offset + H_REAL_SIZE == length){
	hreadr_c(item,&rtemp,offset,H_REAL_SIZE,&iostat);
	*value = rtemp;
      }
    } else if(!memcmp(s,dble_item,ITEM_HDR_SIZE)){
      offset = mroundup(ITEM_HDR_SIZE,H_DBLE_SIZE);
      if(offset + H_DBLE_SIZE == length){
	hreadd_c(item,value, offset,H_DBLE_SIZE,&iostat);
      }
    } else {
      bug_c('f',"Unrecognised type in rdhdd");
    }
    check(iostat);
  }
  hdaccess_c(item,&iostat);				check(iostat);
}
/************************************************************************/
void rdhdc_c(int thandle,Const char *keyword,float *value,Const float *defval)
/** rdhdc -- Read a complex-valued header variable.			*/
/*& mjs 								*/
/*: header-i/o								*/
/*+ FORTRAN call sequence:

	subroutine rdhdc(tno,keyword,value,default)
	integer tno
	character keyword*(*)
	complex value,default

  Read a complex valued header variable.

  Input:
    tno 	The file handle of the data set.
    keyword	The name of the header variable.
    default	The default value to return, if the header variable
		is not found.
  Output:
    value	The value of the header variable. This will be the default
		value, if the variable is missing from the header.	*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  int item;
  char s[ITEM_HDR_SIZE];
  int iostat;
  off_t offset,length;

/* Firstly assume the variable is missing. Try to get it. If successful
   read it. */

  *value = *defval;
  *(value+1) = *(defval+1);
  haccess_c(thandle,&item,keyword,"read",&iostat);	if(iostat)return;
  offset = mroundup(ITEM_HDR_SIZE,H_CMPLX_SIZE);
  length = hsize_c(item) - offset;
  if(length == H_CMPLX_SIZE){
    hreadb_c(item,s,0,ITEM_HDR_SIZE,&iostat);		check(iostat);
    iostat = 0;
    if(!memcmp(s,cmplx_item, ITEM_HDR_SIZE)){
      hreadc_c(item,value,offset,H_CMPLX_SIZE,&iostat);
    }
    check(iostat);
  }
  hdaccess_c(item,&iostat);				check(iostat);
}
/************************************************************************/
void rdhda_c(int thandle,Const char *keyword,char *value,Const char *defval,int len)
/** rdhda -- Read a string-valued header variable.			*/
/*& mjs 								*/
/*: header-i/o								*/
/*+ FORTRAN call sequence:

	subroutine rdhda(tno,keyword,value,default)
	integer tno
	character keyword*(*)
	character value*(*),default*(*)

  Read a string valued header variable.

  Input:
    tno 	The file handle of the data set.
    keyword	The name of the header variable.
    default	The default value to return, if the header variable
		is not found.
  Output:
    value	The value of the header variable. This will be the default
		value, if the variable is missing from the header.	*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  int item;
  char s[ITEM_HDR_SIZE];
  int iostat,dodef;
  off_t length;

/* Firstly assume the variable is missing. Try to get it. If successful
   read it. */

  length = 0;
  dodef = TRUE;
  haccess_c(thandle,&item,keyword,"read",&iostat);
  if(! iostat) {
    length = min( hsize_c(item) - ITEM_HDR_SIZE, len - 1);
    if(length > 0) {
      hreadb_c(item,s,0,ITEM_HDR_SIZE,&iostat); 		check(iostat);
      if(!memcmp(s,char_item,ITEM_HDR_SIZE)){
	hreadb_c(item,value,ITEM_HDR_SIZE,length,&iostat);	check(iostat);
	dodef = FALSE;
      }
    }
    hdaccess_c(item,&iostat);					check(iostat);
  }
  if( dodef ) {
    length = min(strlen(defval),len-1);
    memcpy(value,defval,length);
  }
  *(value+length) = 0;
}
/************************************************************************/
void hdcopy_c(int tin,int tout,Const char *keyword)
/** hdcopy -- Copy a headfer variable from one data set to another.	*/
/*& mjs 								*/
/*: header-i/o								*/
/*+ FORTRAN call sequence:

	subroutine hdcopy(tin,tout,keyword)
	integer tin,tout
	character keyword*(*)

  Copy a header item from one data set to another.

  Input:
    tin 	File handle of the input data set.
    tout	File handle of the output data set.
    keyword	Name of the header variable to be copied.		*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  char buf[MAXSIZE];
  int item_in,item_out;
  int iostat;
  off_t offset,length,size;

  haccess_c(tin,&item_in,keyword,"read",&iostat);	if(iostat)return;
  haccess_c(tout,&item_out,keyword,"write",&iostat);	check(iostat);

  size = hsize_c(item_in);
  offset = 0;
  while(offset < size){
    length = min(size - offset, sizeof(buf));
    hreadb_c(item_in,buf,offset,length,&iostat);	check(iostat);
    hwriteb_c(item_out,buf,offset,length,&iostat);	check(iostat);
    offset += length;
  }
  hdaccess_c(item_in,&iostat);				check(iostat);
  hdaccess_c(item_out,&iostat); 			check(iostat);
}
/************************************************************************/
int hdprsnt_c(int tno,Const char *keyword)
/** hdprsnt -- Determine if a header variable is present.		*/
/*& mjs 								*/
/*: header-i/o								*/
/*+ FORTRAN call sequence:

	logical function hdprsnt(tno,keyword)
	integer tno
	character keyword*(*)

  Check if a particular header variable is present in a data set.

  Input:
    tno 	File handle of the data set to check.
    keyword	Name of the header variable to check for.		*/
/*--									*/
/*----------------------------------------------------------------------*/
{
  if(hexists_c(tno,keyword))return(1);
  else			    return(0);
}
/************************************************************************/
void hdprobe_c(int tno,Const char *keyword,char *descr,size_t length,char *type,int *n)
/** hdprobe -- Determine characteristics of a header variable.		*/
/*& mjs 								*/
/*: header-i/o								*/
/*+ FORTRAN call sequence:

	subroutine hdprobe(tno,keyword,descr,type,n)
	integer tno
	character keyword*(*),descr*(*),type*(*)
	integer n

  Determine characteristics of a particular header variable.
  Inputs:
    tno 	Handle of the data set.
    keyword	Name of the header variable to probe.

  Outputs:
    descr	A formatted version of the item. For single numerics or
		short strings, this is the ascii encoding of the value. For
		large items, this is some message describing the item.
    type	One of:
		  'nonexistent'
		  'integer*2'
		  'integer*8'
		  'integer'
		  'real'
		  'double'
		  'complex'
		  'character'
		  'text'
		  'binary'
    n		Number of elements in the item. Zero implies an error. One
		implies that "descr" is the ascii encoding of the value. */
/*--									*/
/*----------------------------------------------------------------------*/
{
  int item;
  char s[ITEM_HDR_SIZE],buf[MAXSIZE];
  float rtemp,ctemp[2];
  int iostat,unknown,i,itemp,bufit;
  double dtemp;
  int2 jtemp;
  int8 ltemp,ln;
  long long int ltemp2;
  off_t offset,size,asize;

  haccess_c(tno,&item,keyword,"read",&iostat);
  *n = 0;
  ln = 0;
  bufit = 0;
  Strcpy(type,"nonexistent");				if(iostat)return;
  size = hsize_c(item);
  asize = size;

  unknown = FALSE;
  if(size <= ITEM_HDR_SIZE){
    unknown = TRUE;
    size -= ITEM_HDR_SIZE;
  } else {
    hreadb_c(item,s,0,ITEM_HDR_SIZE,&iostat);			check(iostat);
    if(!memcmp(s,real_item,ITEM_HDR_SIZE)){
      offset = mroundup(ITEM_HDR_SIZE,H_REAL_SIZE);
      size -= offset;
      Strcpy(type,"real");
      ln = size / H_REAL_SIZE;
      if(size % H_REAL_SIZE) unknown = TRUE;
      else if(size == H_REAL_SIZE){
	hreadr_c(item,&rtemp,offset,H_REAL_SIZE,&iostat);	check(iostat);
	Sprintf(buf,"%-14.7g",rtemp);
	bufit = 1;
      }
    } else if(!memcmp(s,int_item,ITEM_HDR_SIZE)){
      offset = mroundup(ITEM_HDR_SIZE,H_INT_SIZE);
      size -= offset;
      Strcpy(type,"integer");
      ln = size / H_INT_SIZE;
      if(size % H_INT_SIZE) unknown = TRUE;
      else if(size == H_INT_SIZE){
	hreadi_c(item,&itemp,offset,H_INT_SIZE,&iostat);	check(iostat);
	Sprintf(buf,"%d",itemp);
	bufit = 1;
      }
    } else if(!memcmp(s,int2_item,ITEM_HDR_SIZE)){
      offset = mroundup(ITEM_HDR_SIZE,H_INT2_SIZE);
      size -= offset;
      Strcpy(type,"integer*2");
      ln = size / H_INT2_SIZE;
      if(size % H_INT2_SIZE) unknown = TRUE;
      else if(size == H_INT2_SIZE){
	hreadj_c(item,&jtemp,offset,H_INT2_SIZE,&iostat);	check(iostat);
	Sprintf(buf,"%d",jtemp);
	bufit = 1;
      }
    } else if(!memcmp(s,int8_item,ITEM_HDR_SIZE)){
      offset = mroundup(ITEM_HDR_SIZE,H_INT8_SIZE);
      size -= offset;
      Strcpy(type,"integer*8");
      ln = size / H_INT8_SIZE;
      if(size % H_INT8_SIZE) unknown = TRUE;
      else if(size == H_INT8_SIZE){
	hreadl_c(item,&ltemp,offset,H_INT8_SIZE,&iostat);	check(iostat);
	ltemp2 = ltemp;
	Sprintf(buf,"%lld",ltemp2);
	bufit = 1;
      }
    } else if(!memcmp(s,dble_item,ITEM_HDR_SIZE)){
      offset = mroundup(ITEM_HDR_SIZE,H_DBLE_SIZE);
      size -= offset;
      Strcpy(type,"double");
      ln = size / H_DBLE_SIZE;
      if(size % H_DBLE_SIZE) unknown = TRUE;
      else if(size == H_DBLE_SIZE){
	hreadd_c(item,&dtemp,offset,H_DBLE_SIZE,&iostat);	check(iostat);
	Sprintf(buf,"%-20.10g",dtemp);
	bufit = 1;
      }
    } else if(!memcmp(s,cmplx_item,ITEM_HDR_SIZE)){
      offset = mroundup(ITEM_HDR_SIZE,H_CMPLX_SIZE);
      size -= offset;
      Strcpy(type,"complex");
      ln = size / H_CMPLX_SIZE;
      if(size % H_CMPLX_SIZE) unknown = TRUE;
      else if(size == H_CMPLX_SIZE){
	hreadr_c(item,ctemp,offset,H_CMPLX_SIZE,&iostat);	check(iostat);
	Sprintf(buf,"(%-14.7g,%-14.7g)",ctemp[0],ctemp[1]);
	bufit = 1;
      }
    } else if(!memcmp(s,char_item,ITEM_HDR_SIZE)){
      offset = ITEM_HDR_SIZE;
      size -= offset;
      size = min(size,MAXSIZE-1);
      ln = 1;
      Strcpy(type,"character");
      hreadb_c(item,buf,ITEM_HDR_SIZE,size,&iostat);		check(iostat);
      *(buf+size) = 0;
      bufit = 1;
    } else if(!memcmp(s,binary_item,ITEM_HDR_SIZE)){
      ln = size;
       Strcpy(type,"binary");
    } else{
      Strcpy(type,"text");
      ln = size + ITEM_HDR_SIZE;
      for(i=0; i < ITEM_HDR_SIZE; i++)
	if(!isspace(*(s+i)) && !isprint(*(s+i)))unknown = TRUE;
    }
  }
  hdaccess_c(item,&iostat);					check(iostat);
  if(unknown){
    Strcpy(type,"unknown");
    ln = asize;
  }
  if(!bufit){
    ltemp2 = ln;
    Sprintf(buf,"(%lld elements)",ltemp2);
  }
  if(strlen(buf) > length - 1) {
   bugv_c('f',"Descr buffer overflow in hdprobe for %s",keyword);
  }
  strcpy(descr,buf);
  *n = ln;
}
