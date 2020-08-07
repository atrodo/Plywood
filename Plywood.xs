#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

static SV *hint_keyword;
static SV *parse_sv;

static int is_active(pTHX_)
{
  HE *he;
  HV *hints = GvHV(PL_hintgv);
  if ( hints == NULL )
  {
    return 0;
  }
  he = hv_fetch_ent(hints, hint_keyword, 0, 0);
  if ( he == NULL )
  {
    return 0;
  }
  return SvTRUE(HeVAL(he));
  /*
  return he != NULL && SvTRUE(HeVAL(he));
  */
}

static Perl_keyword_plugin_t next_keyword_plugin;
static int plywood_keyword_plugin(pTHX_
    char *keyword_ptr, STRLEN keyword_len, OP **op_ptr)
{
  if ( !is_active() )
  {
    return next_keyword_plugin(aTHX_ keyword_ptr, keyword_len, op_ptr);
  }

  SV *buffer = newSVpvn(keyword_ptr, keyword_len);
  //warn("Found keyword: %d\n", PL_parser->bufend - PL_parser->bufptr);
  while ( 1 )
  {
    sv_catpvn(buffer, PL_parser->bufptr, PL_parser->bufend - PL_parser->bufptr);
    lex_unstuff(PL_parser->bufend);
    if (!lex_next_chunk(0) )
    {
      break;
    }
  }
  //warn(": %d\n", PL_parser->bufend - PL_parser->bufptr);
  dTHX;
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(buffer);
  PUTBACK;
  int result = call_sv(parse_sv, G_SCALAR);
  SPAGAIN;

  FREETMPS;
  LEAVE;
  /*
  int result = KEYWORD_PLUGIN_DECLINE;
  */

  *op_ptr = newOP(OP_NULL,0);
  return KEYWORD_PLUGIN_STMT;
  return KEYWORD_PLUGIN_DECLINE;
  if ( result == KEYWORD_PLUGIN_DECLINE )
  {
    return next_keyword_plugin(aTHX_ keyword_ptr, keyword_len, op_ptr);
  }
  return result;
}



SV* enframe(OP *op)
{
    SV *result = newSV(0);
    sv_setiv(newSVrv(result, NULL), PTR2IV(op));
    return result;
}

OP* deframe(SV *sv)
{
    OP *result;
    if ( !SvOK(sv) )
    {
      return NULL;
    }
    if ( !SvROK(sv) )
    {
      croak("%s: %s is not an op: %p", "deframe_op", "op", sv);
    }
    {
      IV tmp = SvIV((SV*)SvRV(sv));
      result = INT2PTR(OP *,tmp);
    }
    return result;
}

MODULE = Plywood PACKAGE = Plywood

BOOT:
    wrap_keyword_plugin(plywood_keyword_plugin, &next_keyword_plugin);
    hint_keyword = newSVpvs("Plywood/enabled");
    parse_sv     = newSVpvs("Plywood::parse");

SV*
hint_keyword()
CODE:
    RETVAL = hint_keyword;
OUTPUT:
    RETVAL

MODULE = Plywood PACKAGE = Plywood::Gmrs

void
parse_begin()
CODE:

void
parse_end()
CODE:

void
_newPROG(SV *sv_op)
CODE:
    OP *op = deframe(sv_op);
    lex_start(NULL, NULL, 0);
    newPROG(op);

SV *
_block_end(I32 floor, SV *sv_op)
CODE:
    OP *op = deframe(sv_op);
    SV *result = enframe(block_end(floor, op));
    RETVAL = result;
OUTPUT:
    RETVAL

I32
_block_start(I32 full)
CODE:
    I32 result = block_start(full);
    RETVAL = result;
OUTPUT:
    RETVAL

void
_init_named_cv(SV *sv_name)
CODE:
    OP *op_name = newSVOP(OP_CONST, 0, sv_name);
    Perl_init_named_cv(aTHX_ PL_compcv, op_name);

SV*
_op_convert_list(I32 type, I32 flags, SV* sv_op)
CODE:
    OP *op = deframe(sv_op);
    SV *result = enframe(op_convert_list(type, flags, op));
    RETVAL = result;
OUTPUT:
    RETVAL

SV*
_op_append_list(I32 type, SV *sv_first, SV *sv_last)
CODE:
    OP *first = deframe(sv_first);
    OP *last = deframe(sv_last);
    SV *result = enframe(op_append_list(type, first, last));
    RETVAL = result;
OUTPUT:
    RETVAL

SV*
_op_append_elem(I32 type, SV *sv_first, SV *sv_last)
CODE:
    OP *first = deframe(sv_first);
    OP *last = deframe(sv_last);
    SV *result = enframe(op_append_elem(type, first, last));
    RETVAL = result;
OUTPUT:
    RETVAL

SV*
_newSTATEOP(I32 flags, char* label, SV* sv)
CODE:
    OP* op = deframe(sv);
    if ( PL_parser == NULL )
    {
      lex_start(NULL, NULL, 0);
    }
    OP *o = newSTATEOP(flags, NULL, op);
    SV *result = enframe(newSTATEOP(flags, NULL, op));
    RETVAL = result;
OUTPUT:
    RETVAL

SV*
_newSVOP(I32 type, I32 flags, SV *sv)
CODE:
    SvREFCNT_inc(sv);
    SV *result = enframe(newSVOP(type, flags, sv));
    RETVAL = result;
OUTPUT:
    RETVAL
