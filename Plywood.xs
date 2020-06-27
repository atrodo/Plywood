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
    warn("No Hints\n");
    return 0;
  }
  he = hv_fetch_ent(hints, hint_keyword, 0, 0);
  if ( he == NULL )
  {
    warn("Wrong Hint");
    return 0;
  }
  warn_sv(HeVAL(he));
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
