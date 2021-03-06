c************************************************************************
	program redund
	implicit none
c
c= redund - Determine self-calibration of calibration gains.
c& mchw
c: calibration, map making
c+
c	redund is a MIRIAD task to perform self-calibration of visibility data.
c	Either phase only or amplitude and phase calibration can be performed.
c	The input to SELCAL are a visibility data file, and model images.
c	This program then calculates the visibilities corresponding to the
c	model, accumulates the statistics needed to determine the antennae
c	solutions, and then calculates the self-cal solutions.
c@ vis
c	Name of input visibility data file. No default.
c@ select
c	Standard uv data selection criteria. See the help on "select" for
c	more information.
c@ model
c	Name of the input models. Several models can be given, which can
c	cover different channel ranges and different pointing and sources
c	of the input visibility data. Generally the model should be derived
c	(by mapping and deconvolution) from the input visibility file, so
c	that the channels in the model correspond to channels in the
c	visibility file. The units of the model MUST be JY/PIXEL, rather
c	than JY/BEAM, and should be weighted by the primary beam. The task
c	DEMOS can be used to extract primary beam weighted models from a
c	mosaiced image. If no models are given, a point source model is
c	assumed.
c
c	NOTE: When you give redund a model, it will, by default, select the
c	data associated with this model from the visibility data-set. This
c	includes selecting the appropriate range of channels and the
c	appropriate pointing/source (if options=mosaic is used). If you use
c	a point source model, if it YOUR responsibility	to select the
c	appropriate data.
c@ clip
c	Clip level. For models of intensity, any pixels below the clip level
c	are set to zero. For models of Stokes Q,U,V, or MFS I*alpha models,
c	any pixels whose absolute value is below the clip level are set
c	to zero. Default is 0.
c@ interval
c	The length of time, in minutes, of a gain solution. Default is 5,
c	but use a larger value in cases of poor signal to noise, or
c	if the atmosphere and instrument is fairly stable.
c@ options
c	This gives several processing options. Possible values are:
c	  amplitude  Perform amplitude and phase self-cal.
c	  phase      Perform phase only self-cal.
c	  mfs        This is used if there is a single plane in the input
c	             model, which is assumed to represent the image at all
c	             frequencies. This should also be used if the model has
c	             been derived from MFCLEAN.
c	  relax      Relax the convergence criteria. This is useful when
c	             selfcal'ing with a very poor model.
c	  noscale    Do not scale the gains. By default the gains are scaled
c	             so that the rms gain amplitude is 1. In this way, the
c	             total flux is not contrained to agree with the model.
c	  mosaic     This causes redund to select only those visibilities
c	             whose observing center is within plus or minus three
c	             pixels of the model reference pixel. This is needed
c	             if there are multiple pointings or multiple sources in
c	             the input uv file. By default no observing center
c	             selection is performed.
c	Note that "amplitude" and "phase" are mutually exclusive.
c	The default is options=phase.
c@ minants
c	Data at a given solution interval is deleted  if there are fewer than
c	MinAnts antennae operative during the solution interval. The default
c	is 3 for options=phase and 4 for options=amplitude.
c@ refant
c	This sets the reference antenna, which is given a phase angle of zero.
c	The default, for a given solution interval, is the antennae with the
c	greatest weight.
c@ flux
c	If MODEL is blank, then the flux (Jy) of a point source model can
c	be specified here. The default is 1.
c@ offset
c	This gives the offset in arcseconds of a point source model (the
c	offset is positive to the north and to the east). This parameter is
c	used if the MODEL parameter is blank. The default is 0,0. The
c	amplitude of the point source is chosen so that flux in the model
c	is the same as the visibility flux.
c@ line
c	The visibility linetype to use, in the standard form, viz:
c	  type,nchan,start,width,step
c	Generally if there is an input model, this parameter defaults to the
c	linetype parameters used to construct the map. If you wish to override
c	this, or if the info is not in the header, or if you are using
c	a point source model, this parameter can be useful.
c@ lambda
c	Redundancy weighting. This is a value in the range 0 to 1 which indicates
c	the importance of matching on the redundant baselines. A value of 0
c	gives conventional selfcal, whereas a value of 1 uses only redundancy
c	(which will be unstable). The default is 0.
c--
c
c  History:
c    rjs  13mar90 Original version.
c    rjs  23mar90 Mods to gains file. Eliminated write statements. Check
c		  that the minimum number of antennae are there.
c    rjs  28mar90 Fixed apriori and noscale options. Get it to recalculate
c		  channel bandwidth after every model.
c    rjs  29mar90 Fixed bug in the scaling of SumVM.
c    rjs  31mar90 Increased maxchan.
c    rjs  24apr90 An added error check.
c    rjs  27apr90 Corrected bug in checking for convergence in amp selfcal.
c		  Mildly improved amp selfcal.
c    pjt   2may90 maxchan in selfacc1 now through maxdim.h
c    rjs  16oct90 Check that the vis file is cross-correlation data.
c   mchw  24nov90 Corrected comment and protected sqrt in solve1.
c    rjs  26nov90 Minor changes to the phase-solution routine, to make it
c		  more persistent.
c    mjs  25feb91 Changed references of itoa to itoaf.
c    rjs  25mar91 Added `relax' option. Minor changes to appease flint.
c    rjs   5apr91 Trivial change to get ModelIni to do some polarisation
c		  handling.
c    mjs  04aug91 Replaced local maxants/maxbl to use maxdim.h values
c    rjs  15oct91 Increased hash table size. Extra messages.
c    rjs   1nov91 Polarized and mfs options. Removed out.
c    rjs  29jan92 New call sequence to "Model".
c    rjs   3apr92 Use memalloc routines.
c    rjs  26apr92 Handle clip level better.
c    rjs   1may92 Added nfeeds keyword to output gains header.
c    rjs  17may92 More fiddles to the way clipping is handled.
c    rjs  23jun92 Changes to doc and messages (centre=>center, etc).
c    rjs  22nov92 Added ntau keyword to output gains header.
c    mchw 20apr93 Added flux keyword and option selradec.
c    rjs  29mar93 Fiddle noise calculation. BASANT changes.
c    rjs  18may93 If rms=0, assume rms=1.
c    rjs  19may93 Merge mchw and rjs versions of selfcal.
c    rjs  28jun93 Iterate a bit longer. Better memory allocation.
c    rjs  31aug93 Better amplitude calibration with low S/N data.
c    rjs  24sep93 Doc changes only.
c    rjs   9nov93 Better recording of time of a particular solution interval.
c    rjs  23dec93 Minimum match for linetypes.
c    rjs  30jan95 Change option "selradec" to "mosaic", and update doc
c                 file somewhat. Change to helper routine.
c    rjs  16apr96 Increase select routine arrays.
c    rjs  28aug96 Minor change to get around gcc-related bug. Change care
c                 Dave Rayner.
c    rjs   1oct96 Major tidy up.
c    rjs  19feb97 Better error messages.
c
c  Bugs/Shortcomings:
c   * Selfcal should check that the user is not mixing different
c     polarisations and pointings.
c   * It would be desirable to apply bandpasses, and merge gain tables,
c     apply polarisation calibration, etc.
c------------------------------------------------------------------------
	include 'maxdim.h'
	character version*(*)
	parameter(version='Redund: version 1.0 19-Feb-97')
	integer MaxMod,maxsels,nhead
	parameter(MaxMod=32,maxsels=1024,nhead=3)
c
	character Models(MaxMod)*64,vis*64,ltype*32
	character flag1*8,flag2*8,obstype*32
	integer tvis,tmod,tscr
	integer nModel,minants,refant,nsize(3),nchan,nvis,i,j,d
	real sels(maxsels),clip,interval,offset(2),lstart,lwidth,lstep
	logical phase,amp,doline,noscale,relax,mfs
	real flux(2),lambda
	logical selradec
	integer nred,ant1a(MAXBASE),ant2a(MAXBASE)
	integer      ant1b(MAXBASE),ant2b(MAXBASE)
	character line*80
c
c  Externals.
c
	external header
	character itoaf*3
c
c  Get the input parameters.
c
	call output(version)
	call keyini
	call keyf('vis',vis,' ')
	call SelInput('select',sels,maxsels)
	call mkeyf('model',Models,MaxMod,nModel)
	call keyr('clip',clip,0.)
	call keyr('interval',interval,5.)
	call keyi('minants',minants,0)
	call keyi('refant',refant,0)
	call keyr('flux',flux(1),1.)
	flux(2) = 1
	call keyr('offset',offset(1),0.)
	call keyr('offset',offset(2),0.)
	call keyr('lambda',lambda,0.0)
	lambda = 1-lambda
	if(lambda.le.0.or.lambda.gt.1)
     *		call bug('f','Illegal value for lambda')
	call keyline(ltype,nchan,lstart,lwidth,lstep)
	doline = ltype.ne.' '
	call GetOpt(phase,amp,noscale,relax,mfs,selradec)
	call keyfin
c
c  Check that the inputs make sense.
c
	if(vis.eq.' ') call bug('f','Input visibility file is missing')
	if(interval.le.0) call bug('f','Bad calibration interval')
	interval = interval / (24.*60.)
c
	if(Minants.eq.0)then
	  if(phase)then
	    Minants = 3
	  else if(amp)then
	    Minants = 4
	  endif
	endif
	if(Minants.lt.2)then
	  call bug('f','Bad value for the minants parameter.')
	else if(phase.and.Minants.lt.3)then
	  call bug('w','Phase selfcal with minants < 3 is unusual')
	else if(amp.and.Minants.lt.4)then
	  call bug('w','Amplitude selfcal with minants < 4 is unusual')
	endif
c
c  Set up which are the redundant baselines.
c
	if(nModel.eq.0)then
	  if(abs(offset(1))+abs(offset(2)).eq.0)then
	    call output(
     *		'Model is a point source at the observing center')
	  else
	    call output('Using a point source model')
	  endif
	endif
c
c  Open the visibility file, check that it is interferometer data, and set
c  the line type if necessary.
c
	call uvopen(tvis,vis,'old')
	call rdhda(tvis,'obstype',obstype,'crosscorrelation')
	if(obstype(1:5).ne.'cross')
     *	  call bug('f','The vis file is not cross correlation data')
	if(doline)call uvset(tvis,'data',ltype,nchan,lstart,lwidth,
     *								lstep)
c
c  Determine the flags to the MODELINI routine.
c  p -- Perform pointing selection.
c  l -- Set up line type.
c
	flag1 = ' '
	if(selradec)                flag1(1:1) = 'p'
	if(.not.doline.and..not.mfs)flag1(2:2) = 'l'
c
c  Determine the flags to the MODEL routine.
c  l - Perform clipping.
c  m - Model is a mfs one.
c
	flag2 = 'l'
	if(mfs)flag2(2:2) = 'm'
c
c  Set up which are the redundant baselines.
c
	nred = 0
	do j=2,5
	  do i=1,j-1
	    do d=1,5-j
	      nred = nred + 1
	      ant1a(nred) = i
	      ant2a(nred) = j
	      ant1b(nred) = i + d
	      ant2b(nred) = j + d
	      write(line,'(a,i1,a,i1,a,i1,a,i1,a)')
     *	       'Baselines ',i,'-',j,' and ',i+d,'-',j+d,' are redundant'
	      call output(line)
	    enddo
	  enddo
	enddo
	call output('Number of redundant baseline pairs: '//itoaf(nred))
c
c  Loop over all the models.
c
	if(nModel.eq.0)then
	  call output('Reading the visibility file ...')
	  call SelfSet(.true.,Minants)
	  call SelApply(tvis,sels,.true.)
	  call Model(flag2,tvis,0,offset,flux,tscr,
     *				nhead,header,nchan,nvis)
	  call SelfIni
	  call output('Accumulating statistics ...')
	  call SelfAcc(tscr,nchan,nvis,interval,
     *		nred,ant1a,ant2a,ant1b,ant2b,lambda)
	  call scrclose(tscr)
	else
	  do i=1,nModel
	    call output('Calculating the model for '//Models(i))
	    call SelfSet(i.eq.1,Minants)
	    call xyopen(tmod,Models(i),'old',3,nsize)
	    call ModelIni(tmod,tvis,sels,flag1)
	    call Model(flag2,tvis,tmod,offset,Clip,tscr,
     *				nhead,header,nchan,nvis)
	    call xyclose(tmod)
	    call output('Accumulating statistics ...')
	    if(i.eq.1) call SelfIni
	    call SelfAcc(tscr,nchan,nvis,interval,
     *		nred,ant1a,ant2a,ant1b,ant2b,lambda)
	    call scrclose(tscr)
	  enddo
	endif
c
c  Open the output file to contain the gain solutions.
c
	call HisOpen(tvis,'append')
	call HisWrite(tvis,'REDUND: Miriad '//version)
	call HisInput(tvis,'REDUND')
c
c  Calculate the self-cal gains.
c
	call output('Finding the selfcal/redundant solutions ...')
	call Solve(tvis,phase,relax,noscale,
     *	     refant,interval,nchan,
     *	     nred,ant1a,ant2a,ant1b,ant2b)

c
c  Close up.
c
	call SelfFin
	call HisClose(tvis)
	call uvclose(tvis)
	end
c************************************************************************
	subroutine Chkpolm(tmod)
c
	implicit none
	integer tmod
c
c  Check that the visibility is a total intensity type.
c------------------------------------------------------------------------
        integer iax
        double precision t
c
c  Externals.
c
	logical polspara
c
	call coInit(tmod)
        call coFindAx(tmod,'stokes',iax)
        if(iax.ne.0)then
          call coCvt1(tmod,iax,'ap',1.d0,'aw',t)
          if(.not.polspara(nint(t)))
     *	    call bug('f','Model is not a total intenisty one')
        endif
	call coFin(tmod)
	end
c************************************************************************
	subroutine GetOpt(phase,amp,noscale,relax,mfs,selradec)
c
	implicit none
	logical phase,amp,noscale,relax,mfs,selradec
c
c  Determine extra processing options.
c
c  Output:
c    phase	If true, do phase self-cal.
c    amp	If true, do amplitude/phase self-cal.
c    noscale	Do not scale the model to conserve flux.
c    relax	Relax convergence criteria.
c    mfs	Model is frequency independent, or has been derived
c		from MFCLEAN.
c    selradec	Input uv file contains multiple pointings or multiple
c		sources.
c------------------------------------------------------------------------
	integer nopt
	parameter(nopt=6)
	character opts(nopt)*9
	logical present(nopt)
	data opts/'amplitude','phase    ','noscale  ','relax    ',
     *		  'mfs      ','mosaic   '/
	call options('options',opts,present,nopt)
	amp = present(1)
	phase = present(2)
	noscale = present(3)
	relax = present(4)
	mfs = present(5)
	selradec = present(6)
	if(amp.and.phase)
     *	  call bug('f','Cannot do both amp and phase self-cal')
	if(.not.(amp.or.phase)) phase = .true.
	end
c************************************************************************
	subroutine header(tvis,preamble,data,flags,nchan,
     *						accept,Out,nhead)
	implicit none
	integer tvis,nchan,nhead
	complex data(nchan)
	logical flags(nchan),accept
	real Out(nhead)
	double precision preamble(5)
c
c  This is a service routine called by the model subroutines. It is
c  called every time a visibility is read from the data file.
c
c  Input:
c    tvis	Handle of the visibility file.
c    nhead	The value of nhead
c    nchan	The number of channels.
c    preamble	Preamble returned by uvread.
c    data	A complex array of nchan elements, giving the correlation data.
c		Not used.
c    flags	The data flags. Not used.
c  Output:
c   out 	The nhead values to save with the data. Three values are
c		returned:
c		  out(1) -- baseline number.
c		  out(2) -- time (days) relative to time0.
c		  out(3) -- estimated sigma**2.
c   accept	This determines whether the data is accepted or discarded.
c		It is always accepted unless the baseline number looks bad.
c------------------------------------------------------------------------
	include 'redund.h'
	integer PolI
	parameter(PolI=1)
c
	integer i1,i2,polv
	double precision rms
	logical okpol,okbase
c
c  External.
c
	logical polspara
c
	if(first)then
	  call uvrdvri(tvis,'nants',nants,0)
	  if(nants.le.0)call bug('f',
     *	    'The data file does not contain the number of antennae')
	  if(nants.lt.Minants)call bug('f',
     *	    'Fewer than the minimum number of antennae are present')
	  time0 = int(preamble(4)) + 0.5
	  nbstok = 0
	  nbad = 0
	  first = .false.
	endif
c
c  Accept visibilities only if they are total intensities.
c  and their antenna numbers are OK.
c
	call uvrdvri(tvis,'pol',polv,PolI)
	call basant(preamble(5),i1,i2)
	okpol = polspara(polv)
	okbase = min(i1,i2).ge.1.and.max(i1,i2).le.nants.and.i1.ne.i2
	accept = okpol.and.okbase
c
c  If all looks OK, then calculate the theoretical rms, and store away
c  the information that we need.
c
	if(accept)then
	  out(1) = preamble(5)
	  out(2) = preamble(4) - time0
	  call uvinfo(tvis,'variance',rms)
	  if(rms.le.0)rms=1
	  out(3) = rms
	else if(.not.okpol)then
	  nbstok = nbstok + 1
	else
	  nbad = nbad + 1
	endif
	end
c************************************************************************
	subroutine SelfSet(firstd,Minantsd)
c
	implicit none
	logical firstd
	integer Minantsd
c------------------------------------------------------------------------
	include 'redund.h'
	first = firstd
	Minants = Minantsd
	end
c************************************************************************
	subroutine SelfIni
	implicit none
c
c------------------------------------------------------------------------
	include 'redund.h'
	integer i,SolSize
c
c  Externals.
c
	integer prime,MemBuf
c
	nHash = prime(maxHash-1)
	do i=1,nHash+1
	  Hash(i) = 0
	enddo
c
c  Determine the indices into the buffer. These are offsets into the
c  one scratch buffer. This scatch buffer is used as 5 arrays, namely
c    complex SumVM(nBl,maxSol),Gains(nants,maxSol)
c    real SumVV(nBl,maxSol),SumMM(maxSol),Weight(nBl,maxSol)
c    real Count(maxSol)
c
	nBl = (nants*(nants-1))/2
	SolSize = 3 + 7*nBl + 2*nants
	maxSol = min(nHash,max(minSol,(MemBuf()-10)/SolSize))
	nSols = 0
	TotVis = 0
	call MemAlloc(pSumVM,2*maxSol*nBl,'c')
	call MemAlloc(pSumVV,maxSol*nBl,'r')
	call MemAlloc(pSumMM,maxSol,'r')
	call MemAlloc(pWeight,2*maxSol*nBl,'r')
	call MemAlloc(pCount,maxSol,'r')
	call MemAlloc(pGains,maxSol*nants,'c')
	call MemAlloc(prTime,maxSol,'r')
	call MemAlloc(pStptim,maxSol,'r')
	call MemAlloc(pStrtim,maxSol,'r')
c
	end
c************************************************************************
	subroutine SelfFin
c
	implicit none
c
c  Release allocated memory.
c
c------------------------------------------------------------------------
	include 'redund.h'
c
	call MemFree(pSumVM,2*maxSol*nBl,'c')
	call MemFree(pSumVV,maxSol*nBl,'r')
	call MemFree(pSumMM,maxSol,'r')
	call MemFree(pWeight,2*maxSol*nBl,'r')
	call MemFree(pCount,maxSol,'r')
	call MemFree(pGains,maxSol*nants,'c')
	call MemFree(prTime,maxSol,'r')
	call MemFree(pstpTim,maxSol,'r')
	call MemFree(pstrTim,maxSol,'r')
	end
c************************************************************************
	subroutine SelfAcc(tscr,nchan,nvis,interval,
     *		nred,ant1a,ant2a,ant1b,ant2b,lambda)
c
	implicit none
	integer tscr,nchan,nvis,nred
	integer ant1a(nred),ant2a(nred),ant1b(nred),ant2b(nred)
	real interval,lambda
c
c  This calls the routine which does the real work in accumulating
c  the statistics about a model.
c
c  Input:
c    tscr	The handle of the scratch file, which contains the visibility
c		and model information.
c    nchan	The number of channels in the scratch file.
c    nvis	The number of visbilities in the scratch file.
c    Interval	The self-cal gain interval.
c-----------------------------------------------------------------------
	include 'redund.h'
	integer pData,pWts
c
	TotVis = TotVis + nVis
	call memAlloc(pData,nchan*nbl,'c')
	call memAlloc(pWts,nchan*nbl,'r')
	call SelfAcc1(tscr,nchan,nvis,nBl,nants,maxSol,nSols,
     *	  nhash,Hash,Indx,interval,
     *	  Memc(pSumVM),Memr(pSumVV),Memr(pSumMM),
     *	  Memr(pWeight),Memr(pCount),Memr(prTime),Memr(pstpTim),
     *	  Memr(pstrTim),memc(pData),memr(pWts),
     *	  nred,ant1a,ant2a,ant1b,ant2b,lambda)
	call memFree(pData,nchan*nbl,'c')
	call memFree(pWts,nchan*nbl,'r')
	end
c************************************************************************
	subroutine SelfAcc1(tscr,nchan,nvis,nBl,nants,maxSol,nSols,
     *	  nHash,Hash,Indx,interval,
     *	  SumVM,SumVV,SumMM,Weight,Count,rTime,StpTime,StrTime,
     *	  Data,Wts,nred,ant1a,ant2a,ant1b,ant2b,lambda)
c
	implicit none
	integer tscr,nchan,nvis,nBl,maxSol,nSols,nants
	integer nHash,Hash(nHash+1),Indx(nHash)
	real interval,lambda
	complex SumVM(nBl,maxSol,2),Data(nchan,nbl)
	real SumVV(nBl,maxSol),SumMM(maxSol),Weight(nBl,maxSol,2)
	real Count(maxSol),rTime(maxSol),StpTime(maxSol)
	real StrTime(maxSol),Wts(nchan,nbl)
	integer nred,ant1a(nred),ant2a(nred),ant1b(nred),ant2b(nred)
c
c  This reads through the scratch file which contains the visibility
c  and the model. It finds (via a hash table) the index of the slot
c  which is being used to store info for this time interval. It then
c  accumulates various statistics into the appropriate arrays. These
c  statistics are eventually used to determine the self-cal solutions.
c
c  Input:
c    tscr	Handle of the scratch file.
c    nchan	Number of channels.
c    nvis	Number of visibilities.
c    nants	Number of antennae.
c    nBl	Number of baselines = nants*(nants-1)/2.
c    maxSol	Max number of solution slots.
c    nSols	Actual number of solution slots being used.
c    nHash	Hash table size.
c    interval	Self-cal interval.
c  Input/Output:
c  In the following, t=time (within a solution interval), f=channels,
c		b=baseline number, a = antenna number.
c    Time	The integer time, nint((preamble(4)-time0)/interval).
c    Hash	Hash table, used to locate a solution interval.
c    Indx	Index from hash table to solution interval.
c    SumVM	Sum(over t,f)conjg(Model)*Vis/sigma**2. Varies with b.
c    SumVV	Sum(over t,f)|Model|**2/sigma**2. Varies with b.
c    SumMM	Sum(over t,f,b) |Vis|**2/sigma**2.
c    Weight	Sum(over t,f) 1/sigma**2. Varies with b.
c    Count	Sum(over t,f,b) 1.
c    rTime	Sum(over t,f,b) t.
c
c  The Visibility Records:
c    The scratch file consists of "nvis" records, each of size nhead+5*nchan
c    The first nhead=3 values are
c      baseline number
c      time
c      estimated sigma**2
c
c  The Hash Table:
c    The hash table is a cyclic buffer. Each element in the buffer potentially
c    holds info pertaining to one time interval. A value of 0 in Hash indicates
c    an unused slot, whereas a non-zero number indicates a used slot. This
c    non-zero number is 2*itime+1, which is always odd, and is unique to a
c    particular time.
c
c    The last entry in the hash table (element nHash+1) is always zero, so the
c    check for the end of the buffer can be placed outside the main loop.
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer maxlen,nhead
	parameter(nhead=3,maxlen=5*maxchan+nhead)
	integer i,j,k,ihash,itime,bl,i1,i2,length,iprev,k0
	real Out(maxlen),Wt,tprev
	logical buffered
c
	buffered = .false.
	tprev = 0
	iprev = 0
	if(nchan.gt.maxchan) call bug('f','Too many channels')
	length = nhead + 5*nchan
c
	do k=1,nbl
	  do i=1,nchan
	    Data(i,k) = 0
	    Wts(i,k) = 0
	  enddo
	enddo
c
	do j=1,nvis
	  call scrread(tscr,Out,(j-1)*length,length)
	  itime = nint(Out(2)/interval)
	  ihash = 2*itime + 1
	  i = mod(itime,nHash)
	  if(i.le.0) i = i + nHash
c
c  Find this entry in the hash table.
c
	  dowhile(Hash(i).ne.0.and.Hash(i).ne.ihash)
	    i = i + 1
	  enddo
	  if(i.gt.nHash)then
	    i = 1
	    dowhile(Hash(i).ne.0.and.Hash(i).ne.ihash)
	      i = i + 1
	    enddo
	  endif
c
c  It was not in the hash table. Add a new entry.
c
	  if(Hash(i).eq.0)then
	    nSols = nSols + 1
	    if(nSols.ge.maxSol) call bug('f','Hash table overflow')
	    Hash(i) = ihash
	    Indx(i) = nSols
	    do k=1,nBl
	      SumVM(k,nSols,1) = (0.,0.)
	      SumVM(k,nSols,2) = (0.,0.)
	      SumVV(k,nSols) = 0.
	      Weight(k,nSols,1) = 0.
	      Weight(k,nSols,2) = 0.
	    enddo
	    SumMM(nSols) = 0
	    Count(nSols) = 0
	    rTime(nSols) = 0
	    StpTime(nSols) = Out(2)
	    StrTime(nSols) = Out(2)
	 endif
c
c  We have found the slot containing the info. Accumulate in the
c  info about this visibility record.
c
	  i = Indx(i)
	  wt = 0.5*lambda/Out(3)
	  call basant(dble(out(1)),i1,i2)
	  bl = (i2-1)*(i2-2)/2 + i1
	  StpTime(i) = min(StpTime(i),out(2))
	  StrTime(i) = max(StrTime(i),out(2))
	  do k=nhead+1,nhead+5*nchan,5
	    if(out(k+4).gt.0)then
	      SumVM(bl,i,1) = SumVM(bl,i,1) +
     *		Wt*cmplx(Out(k),-Out(k+1))*cmplx(Out(k+2),Out(k+3))
	      SumVV(bl,i) = SumVV(bl,i) + 
     *				Wt*(Out(k)**2 + Out(k+1)**2)
	      SumMM(i) = SumMM(i) + Wt * (Out(k+2)**2 + Out(k+3)**2)
	      Weight(bl,i,1) = Weight(bl,i,1) + Wt
	      Count(i) = Count(i) + 1
	      rTime(i) = rTime(i) + Out(2)
	    endif
	  enddo
c
c  Flush the saved integration, if needed.
c
	  if(abs(tprev-Out(2)).gt.5.0/(3600.*24.).and.buffered)
     *	    call BufFlush(Data,Wts,SumVM(1,iprev,2),
     *			Weight(1,iprev,2),nchan,nbl,nants,
     *			nred,ant1a,ant2a,ant1b,ant2b)
c
c  Save the current data.
c
	  k0 = 1
	  do k=nhead+1,nhead+5*nchan,5
	    Data(k0,bl) = cmplx(Out(k+2),Out(k+3))
	    if(out(k+4).gt.0)Wts(k0,bl) = Wt*(1-lambda)/lambda
	    k0 = k0 + 1
	  enddo
	  tprev = Out(2)
	  iprev = i
	  buffered = .true.
	enddo
c
	if(buffered)
     *	  call BufFlush(Data,Wts,SumVM(1,iprev,2),
     *			Weight(1,iprev,2),nchan,nbl,nants,
     *			nred,ant1a,ant2a,ant2b,ant2b)
	end
c************************************************************************
	subroutine BufFlush(Data,Wts,SumVM,Weight,nchan,nbase,nants,
     *			nred,ant1a,ant2a,ant1b,ant2b)
c
	implicit none
	integer nchan,nbase,nants
	complex data(nchan,nbase),SumVM(nbase)
	real Wts(nchan,nbase),Weight(nbase)
	integer nred,ant1a(nred),ant2a(nred),ant1b(nred),ant2b(nred)
c
c  Accumulate.
c------------------------------------------------------------------------
	integer k,j,i,bl1,bl2
	real wt
	complex temp
c
	do k=1,nred
	  bl1 = (ant2a(k)-1)*(ant2a(k)-2)/2 + ant1a(k)
	  bl2 = (ant2b(k)-1)*(ant2b(k)-2)/2 + ant1b(k)
	  do i=1,nchan
	    temp = Data(i,bl1)*conjg(Data(i,bl2))
	    Wt = min(Wts(i,bl1),Wts(i,bl2))
	    SumVM(k) = SumVM(k) + Wt*temp
	    Weight(k) = Weight(k) + Wt
	  enddo
	enddo
c
	do j=1,nbase
	  do i=1,nchan
	    Data(i,j) = 0
	    Wts(i,j) = 0
	  enddo
	enddo
c
	end
c************************************************************************
	subroutine Solve(tgains,phase,relax,noscale,refant,
     *					     interval,nchan,
     *	     nred,ant1a,ant2a,ant1b,ant2b)
c
	implicit none
	integer tgains
	logical phase,relax,noscale
	integer refant,nchan
	real interval
	integer nred,ant1a(nred),ant2a(nred),ant1b(nred),ant2b(nred)
c
c  We have previously accumulated all the statistics that we nee. Now we
c  are ready to determine the self-cal solutions.
c
c------------------------------------------------------------------------
	include 'redund.h'
	character line*64
c
c  Externals.
c
	character itoaf*8
c
	if(nbad.ne.0) call bug('w',
     *	  'No. correlations with bad baseline numbers: '//
     *	  itoaf(nbad*nchan))
	if(nbstok.ne.0)call output(
     *	  'Correlations with inappropriate Stokes type discarded: '//
     *	  itoaf(nbstok*nchan))
	line = 'Total number of correlations being used: '//
     *	  itoaf(TotVis*nchan)
	call HisWrite(tgains,'REDUND: '//line)
	call output(line)
	line = 'Total number of solution intervals: '//itoaf(nSols)
	call HisWrite(tgains,'REDUND: '//line)
	call output(line)
c
c  Determine all the gain solutions.
c
	call Solve1(tgains,nSols,nBl,nants,phase,relax,noscale,
     *	  minants,refant,Time0,interval,Indx,
     *	  Memc(pSumVM),Memr(pSumVV),Memr(pSumMM),Memc(pGains),
     *	  Memr(pWeight),Memr(pCount),memr(prTime),
     *	  Memr(pStpTim),Memr(pStrTim),
     *	  nred,ant1a,ant2a,ant1b,ant2b)
c
	end
c************************************************************************
	subroutine Solve1(tgains,nSols,nBl,nants,phase,relax,
     *	  noscale,minants,refant,Time0,interval,TIndx,
     *	  SumVM,SumVV,SumMM,Gains,Weight,Count,rTime,
     *	  StpTime,StrTime,
     *	  nred,ant1a,ant2a,ant1b,ant2b)
c
	implicit none
	integer tgains
	logical phase,relax,noscale
	integer nSols,nBl,nants,minants,refant
	integer TIndx(nSols)
	complex SumVM(nBl,nSols,2),Gains(nants,nSols)
	real SumVV(nBl,nSols),SumMM(nSols),Weight(nBl,nSols,2)
	real Count(nSols),rTime(nSols),StpTime(nSols),StrTime(nSols)
	real interval
	double precision Time0
	integer nred,ant1a(nred),ant2a(nred),ant1b(nred),ant2b(nred)

c
c  This runs through all the accumulated data, and calculates the
c  selfcal solutions.
c
c  Input:
c    phase
c    relax
c    nSols
c    nBl
c    nants
c    minants
c    refant
c    time
c    Weight
c    Count
c    rTime
c    SumMM
c    SumVM
c    SumVV
c  Scratch:
c    TIndx
c    Gains
c------------------------------------------------------------------------
	include 'maxdim.h'
	logical Convrg
	integer i,k,k0,nbad,iostat,item,offset,header(2),nmerge
	double precision dtime,dtemp
c
c  Externals.
c
	character itoaf*8
c
c  Sort the self-cal solutions into order of increasing time.
c
	call sortidxr(nSols,StpTime,TIndx)
c
c  Merge together short, adjacent, solution intervals.
c
	call Merger(nSols,nBl,TIndx,interval,StpTime,StrTime,
     *	  SumVM,SumVV,SumMM,Weight,Count,rTime,nmerge)
	if(nmerge.gt.0)call output(
     *	  'Solution intervals merged together: '//itoaf(nmerge))
c
c  Now calculate the solutions.
c
	nbad = 0
	do k=1,nSols
	  if(Count(k).gt.0)then
	    call Solve2(nbl,nants,SumVM(1,k,1),SumVV(1,k),Weight(1,k,1),
     *	      SumVM(1,k,2),Weight(1,k,2),nred,ant1a,ant2a,ant1b,ant2b,
     *	      phase,relax,minants,refant,Gains(1,k),Convrg)
	    if(.not.Convrg)then
	      nbad = nbad + 1
	      Count(k) = 0
	    endif
	  endif
	  if(Count(k).eq.0)then
	    do i=1,nants
	      Gains(i,k) = 0
	    enddo
	  endif
	enddo
c
c  Write out some info to wake the user up from his/her slumber.
c
	if(nbad.ne.0)call bug('w','Intervals with no solution: '//
     *							itoaf(nbad))
	if(nbad+nmerge.eq.nsols) call bug('f','No solutions were found')
c
c  Scale the gains if needed.
c
	if(.not.(noscale.or.phase))call GainScal(Gains,nants,nSols)
c
c  Calculate statistics.
c
	call CalcStat(tgains,nsols,nbl,nants,SumVM,SumMM,SumVV,
     *	  Weight,Count,Gains)
c
c  Write the gains out to a gains table.
c
	call haccess(tgains,item,'gains','write',iostat)
	if(iostat.ne.0)then
	  call bug('w','Error opening output gains item')
	  call bugno('f',iostat)
	endif
	header(1) = 0
	header(2) = 0
	offset = 0
	call hwritei(item,header,offset,8,iostat)
	if(iostat.ne.0)then
	  call bug('w','Error opening output gains item')
	  call bugno('f',iostat)
	endif
	offset = 8
	do k=1,nSols
	  k0 = TIndx(k)
	  if(Count(k0).gt.0)then
	    dtime = rTime(k0) / Count(k0) + time0
	    call hwrited(item,dtime,offset,8,iostat)
	    offset = offset + 8
	    if(iostat.eq.0)call hwriter(item,gains(1,k0),offset,8*nants,
     *								iostat)
	    offset = offset + 8*nants
	    if(iostat.ne.0)then
	      call bug('w','I/O error while writing to gains item')
	      call bugno('f',iostat)
	    endif
	  endif
	enddo
	call hdaccess(item,iostat)
	if(iostat.ne.0)then
	  call bug('w','Error closing output gains item')
	  call bugno('f',iostat)
	endif
c
c  Write some extra information for the gains table.
c
	dtemp = interval
	call wrhdd(tgains,'interval',dtemp)
	call wrhdi(tgains,'ngains',nants)
	call wrhdi(tgains,'nsols',nsols-nbad-nmerge)
	call wrhdi(tgains,'nfeeds',1)
	call wrhdi(tgains,'ntau',0)
c
	end
c************************************************************************
	subroutine Merger(nSols,nBl,TIndx,interval,StpTime,StrTime,
     *	  SumVM,SumVV,SumMM,Weight,Count,rTime,nmerge)
c
	implicit none
	integer nSols,nBl,nmerge
	integer tIndx(nSols)
	real interval
	real StpTime(nSols),StrTime(nSols),rTime(nSols)
	complex SumVM(nBl,nSols,2)
	real SumVV(nBl,nSols),SumMM(nSols),Weight(nBl,nSols,2)
	real Count(nSols)
c
c  Merge together adjacent solution intervals if the total span of time is
c  last than "interval".
c
c  Input:
c    nSols
c    nBl
c    TIndx
c    interval
c  Input/Output:
c    SumVM
c    SumVV
c    SumMM
c    Weight
c    Count
c    rTime
c    StpTime
c    StrTime
c  Output:
c    nmerge	The number of mergers.
c------------------------------------------------------------------------
	integer k,k0,kp,i,k1st
	logical more
c
	nmerge = 0
c
c  Find the first solution slot with some valid data.
c
	k1st = 0
	more = .true.
	dowhile(k1st.lt.nSols.and.more)
	  k1st = k1st + 1
	  kp = TIndx(k1st)
	  if(Count(kp).le.0)then
	    nmerge = nmerge + 1
	  else
	    more = .false.
	  endif
	enddo
	if(nmerge.eq.nSols)call bug('f','No valid data')
c
	do k=k1st+1,nSols
	  k0 = TIndx(k)
	  if(Count(k0).le.0)then
	    nmerge = nmerge + 1
	  else if(StrTime(k0)-StpTime(kp).le.interval)then
	    nmerge = nmerge + 1
	    StrTime(kp) = StrTime(k0)
	    Count(kp) = Count(kp) + Count(k0)
	    Count(k0) = 0
	    SumMM(kp) = SumMM(kp) + SumMM(k0)
	    rTime(kp) = rTime(kp) + rTime(k0)
	    do i=1,nBl
	      SumVM(i,kp,1) = SumVM(i,kp,1) + SumVM(i,k0,1)
	      SumVM(i,kp,2) = SumVM(i,kp,2) + SumVM(i,k0,2)
	      SumVV(i,kp) = SumVV(i,kp) + SumVV(i,k0)
	      Weight(i,kp,1) = Weight(i,kp,1) + Weight(i,k0,1)
	      Weight(i,kp,2) = Weight(i,kp,2) + Weight(i,k0,2)
	    enddo
	  else
	    kp = k0
	  endif
	enddo
c
	end
c************************************************************************
	subroutine GainScal(Gains,nants,nSols)
c
	implicit none
	integer nants,nSols
	complex Gains(nants,nSols)
c
c  Scale the gains to have an rms value of 1.
c
c------------------------------------------------------------------------
	integer i,j,N
	real Sum,fac
	complex g
c
	Sum = 0
	N = 0
	do j=1,nsols
	  do i=1,nants
	    g = Gains(i,j)
	    if(abs(real(g))+abs(aimag(g)).gt.0)then
	      N = N + 1
	      Sum = Sum + real(g)**2 + aimag(g)**2
	    endif
	  enddo
	enddo
c
	if(N.eq.0)return
	fac = sqrt(N / Sum)
c
	do j=1,nSols
	  do i=1,nants
	    Gains(i,j) = fac * Gains(i,j)
	  enddo
	enddo
c
	end
c************************************************************************
	subroutine Solve2(nbl,nants,SumVM,SumVV,Weight,
     *	    CVis,CWts,nred,ant1a,ant2a,ant1b,ant2b,
     *	    phase,relax,Minants,Refant,GainOut,Convrg)
c
	implicit none
	integer nbl,nants,Minants,RefAnt
	real SumVV(nbl),Weight(nBl)
	complex SumVM(nbl),GainOut(nants)
	logical phase,relax,Convrg
c
	integer nred,ant1a(nred),ant2a(nred),ant1b(nred),ant2b(nred)
	complex CVis(nred)
	real Cwts(nred)
c
c  Routine to do various fooling around before a routine is called to
c  determine the gain solution. The fooling around makes the inner loop
c  of the gain solution pretty clean.
c
c  Inputs:
c    nants	Number of antennae.
c    nbl	Number of baselines, must equal nants*(nants-1)/2
c    Minants	The minimum number of antenna that must be present.
c    RefAnt	The antenna to refer solutions to.
c    SumVM	The weighted sum of the visibilities.
c    SumVV	The weighted sum of the visibilities moduli squared.
c
c  Outputs:
c    GainOut	The complex gains to apply to correct the data.
c    Convrg	Whether it converged or not.
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer b1(MAXBASE),b2(MAXBASE)
	integer rb1(MAXBASE),rb2(MAXBASE),rb3(MAXBASE),rb4(MAXBASE)
	integer i,j,k,Nblines,nantenna,nref,nredund
	complex Sum(MAXANT),Sum3(MAXANT),Gain(MAXANT),Temp
	complex SVM(MAXBASE),CV(MAXBASE)
	real Sum2(MAXANT),Wts(MAXANT)
	real SVV(MAXBASE)
	integer Indx(MAXANT)
c
c  Externals.
c
	integer ismax
c
c  Check.
c
	if(nbl.ne.nants*(nants-1)/2)
     *	  call bug('f','Number of antennae and baselines do not agree')
	if(nants.gt.MAXANT)call bug('f','Too many antennas')
c
c  Some intialising.
c
	do k=1,nants
	  Indx(k) = 0
	  Wts(k) = 0
	enddo
c
c  Now find which baselines are there, and map the antenna numbers,
c
c  Squeeze out unnecessary baselines and antenna from this time slice.
c  This also works out the map from baseline number to "notional antenna
c  number" pairs, contained in B1 and B2. INDX is set up to contain the
c  map from notional antenna number to the FITS-file antenna number.
c  Thus baseline i, corresponds to notional antenna nos. B1(i) and B2(i).
c  If INDX(k).eq.B1(i), then the real antenna no. is K.
c
c  This fancy compression is needed to give good clean inner loops
c  (no IF statements) in the gain solution routines.
c
	nantenna = 0
	NBlines = 0
	k = 0
	do j=2,nants
	  do i=1,j-1
	    k = k + 1
	    if(SumVV(k).gt.0)then
	      Wts(i) = Wts(i) + Weight(k)
	      Wts(j) = Wts(j) + Weight(k)
c
	      NBlines = NBlines + 1
	      SVM(NBlines) = SumVM(k)
	      SVV(NBlines) = SumVV(k)
c
	      if(Indx(i).eq.0)then
		nantenna = nantenna + 1
		Indx(i) = nantenna
	      endif
	      B1(NBlines) = Indx(i)
c
	      if(Indx(j).eq.0)then
		nantenna = nantenna + 1
		Indx(j) = nantenna
	      endif
	      B2(NBlines) = Indx(j)
	    endif
	  enddo
	enddo
c
c  Fiddle with the redundant baselines now.
c
	nredund = 0
	do k=1,nred
	  if(CWts(k).gt.0.and.
     *	     indx(ant1a(k)).gt.0.and.indx(ant2a(k)).gt.0.and.
     *	     indx(ant1b(k)).gt.0.and.indx(ant2b(k)).gt.0)then
	    nredund = nredund + 1
	    rb1(nredund) = Indx(ant1a(k))
	    rb2(nredund) = Indx(ant2a(k))
	    rb3(nredund) = Indx(ant1b(k))
	    rb4(nredund) = Indx(ant2b(k))
	    CV(nredund) = CVis(k)
	  endif
	enddo
c
c  Check that we have enough antennae. More initialisation.
c  Call the routine to get the solution.
c
	if(Minants.gt.nantenna)then
	  Convrg = .false.
	else if(phase)then
	  call phasol  (NBlines,nantenna,Sum,SVM,b1,b2,gain,convrg)
	  convrg = convrg.or.relax
	else
	  call amphasol(NBlines,nredund,nantenna,Sum,Sum2,Sum3,
     *		SVM,SVV,CV,b1,b2,rb1,rb2,rb3,rb4,gain,convrg)
	  convrg = convrg.or.relax
	endif
c
c  If it converged, unsqueeze the gains, and refer them to the reference
c  antenna.
c
	if(Convrg)then
	  do i=1,nants
	    if(Indx(i).eq.0)then
	      GainOut(i) = (0.,0.)
	    else
	      GainOut(i) = Gain(Indx(i))
	    endif
	  enddo
c
	  nref = Refant
	  if(nref.ne.0)then
	    if(Wts(nref).le.0) nref = 0
	  endif
	  if(nref.eq.0) nref = ismax(nants,Wts,1)
	  Temp = conjg(GainOut(nRef))/abs(GainOut(nRef))
	  do i=1,nants
	    GainOut(i) = Temp * GainOut(i)
	  enddo
	endif
c
	end
c************************************************************************
	subroutine CalcStat(tgains,nsols,nbl,nants,SumVM,SumMM,SumVV,
     *					Weight,Count,Gains)
c
	implicit none
	integer tgains
	integer nsols,nbl,nants
	complex SumVM(nbl,nsols),Gains(nants,nsols)
	real SumMM(nsols),SumVV(nbl,nsols),Weight(nbl,nsols)
	real Count(nsols)
c
c  Accumulate the various statistics.
c
c------------------------------------------------------------------------
	include 'maxdim.h'
	real Resid,SumChi2,SumPhi,SumExp,SumWts,SumAmp,Phi,Amp,Sigma
	real m1,m2,wt
	complex g1,g2
	integer i,j,k,sol
	character line*80
c
	SumChi2 = 0
	SumPhi = 0
	SumExp = 0
	SumWts = 0
	SumAmp = 0
c
c  Calculate residual. Note that if the residuals is so small that rounding
c  error may be a problem (this will only happen with dummy data), then take
c  its absolute value.
c
	do sol=1,nSols
	  if(Count(sol).gt.0)then
	    k = 0
	    Resid = SumMM(sol)
	    do j=2,nants
	      do i=1,j-1
		k = k + 1
		Wt = Weight(k,sol)
		g1 = conjg(Gains(i,sol))
		g2 = Gains(j,sol)
		m1 = real(g1)**2 + aimag(g1)**2
		m2 = real(g2)**2 + aimag(g2)**2
		if(Wt.gt.0.and.m1.gt.0.and.m2.gt.0)then
		  Resid = Resid - 2*real(g1*g2*SumVM(k,sol)) +
     *			m1*m2*SumVV(k,sol)
		  SumWts = SumWts + Wt
		  call amphase(g1*g2,amp,phi)
		  SumPhi = SumPhi + Wt*phi**2
		  SumAmp = SumAmp + Wt*(1-amp)**2
		endif
	      enddo
	    enddo
	    SumChi2 = SumCHi2 + abs(Resid)
	    SumExp = SumExp + Count(sol)
	  endif
	enddo
c
	Phi = sqrt(abs(SumPhi/(2*SumWts)))
	Amp = sqrt(abs(SumAmp/(2*SumWts)))
	Sigma = sqrt(abs(SumChi2/SumExp))
	write(line,'(a,f6.1)')'Rms of the gain phases (degrees):',phi
	call output(line)
	call HisWrite(tgains,'REDUND: '//line)
	write(line,'(a,1pg10.3)')'Rms deviation of gain from 1:',amp
	call output(line)
	call HisWrite(tgains,'REDUND: '//line)
	write(line,'(a,1pg10.3)')
     *	  'Ratio of Actual to Theoretical noise:',Sigma
	call output(line)
	call HisWrite(tgains,'REDUND: '//line)
c
	end
c************************************************************************
	subroutine phasol(Nblines,nants,Sum,SumVM,b1,b2,Gain,Convrg)
c
	implicit none
	logical Convrg
	integer Nblines,nants
	integer b1(NBlines),b2(NBlines)
	complex SumVM(Nblines),Gain(nants),Sum(nants)
c
c  Solve for the phase corrections which minimise the error. This uses
c  a nonlinear Jacobi iteration, as suggested by Fred Schwab in "Adaptive
c  calibration of radio interferomter data", SPIE Vol. 231, 1980
c  International Optical Computing Conference (pp 18-24). The damping
c  heuristics are copied from AIPS ASCAL.
c
c  Input:
c    NBlines	Number of baselines.
c    nants	Number of antennae.
c    b1,b2	This gives the antennae pair for each baseline.
c    SumVM	Sum of Model*conjg(Vis)
c  Scratch:
c    Sum
c  Output:
c    Convrg	If .true., then the algorithm converged.
c    Gain	The antenna gain solution.
c------------------------------------------------------------------------
	integer MaxIter
	real Epsi,Epsi2
	parameter(MaxIter=100,Epsi=1.e-8,Epsi2=1.e-4)
c
	real Factor,Change
	complex Temp
	integer Niter,i
c
c  Initialise.
c
	do i=1,nants
	  Gain(i) = (1.,0.)
	  Sum(i) = (0.,0.)
	enddo
c
	Factor = 0.8
	if(nants.le.6)Factor = 0.5
c
c  Iterate.
c
	Convrg = .false.
	Niter = 0
	do while(.not.Convrg.and.Niter.lt.MaxIter)
	  Niter = Niter + 1
c
c  Sum the contributions over the baselines. Note that the following
c  loop has a dependency.
c
	  do i=1,nblines
	    Sum(b1(i)) = Sum(b1(i)) + Gain(b2(i)) *	  SumVM(i)
	    Sum(b2(i)) = Sum(b2(i)) + Gain(b1(i)) * conjg(SumVM(i))
	  enddo
c
c  Update the gains. The following will be flagged as a short loop
c  on the Cray, if we assume we have fewer than 32 antennae. Hopefully
c  this will vectorise. For "typical" cases, the absolute value function
c  in the next loop takes up about 30-40% of the run time of this routine
c  on a VAX.
c
	  Change = 0
c#maxloop 32
	  do i=1,nants
	    Temp = ( Sum(i)/abs(Sum(i)) )
	    Temp = Gain(i) + Factor * ( Temp - Gain(i) )
	    Temp = Temp/abs(Temp)
	    Change = Change + real(Gain(i)-Temp)**2
     *			    + aimag(Gain(i)-Temp)**2
	    Gain(i) = Temp
	    Sum(i) = (0.,0.)
	  enddo
	  Convrg = Change/nants .lt. Epsi
	enddo
	Convrg = Change/nants .lt. Epsi2
	end
c************************************************************************
	subroutine amphasol(nbl,nreds,nants,Sum,Sum2,Sum3,
     *		SumVM,SumVV,CV,b1,b2,rb1,rb2,rb3,rb4,gain,convrg)
c
	implicit none
	logical Convrg
	integer nbl,nants,nreds
	integer b1(nbl),b2(nbl)
	integer rb1(nreds),rb2(nreds),rb3(nreds),rb4(nreds)
	complex SumVM(nbl),Gain(nants),Sum(nants),CV(nreds),Sum3(nants)
	real SumVV(nbl),Sum2(nants)
c
c  Solve for the amplitudes and phase corrections which minimise
c  error. Algorithm is again Schwab's Jacobi iteration. The damping
c  heuristics are copied from AIPS ASCAL or dreamed up by me (as was the
c  initial gain estimate).
c
c  Input:
c    nbl	Number of baselines.
c    nants	Number of antennae.
c    b1,b2	This gives the antennae pair for each baseline.
c    SumVM	Sum of Model*conjg(Vis), for each baseline.
c    SumVV	Sum of Vis*conjg(Vis), for each baseline.
c  Scratch:
c    Sum
c    Sum2
c    Sum3
c  Output:
c    Convrg	If .true., then the algorithm converged.
c    Gain	The antenna gain solution.
c
c------------------------------------------------------------------------
	integer maxiter
	real Epsi,Epsi2
	parameter(maxiter=100,Epsi=1.e-8,Epsi2=1e-4)
	integer i,Niter
	real a11,a12,a21,a22,det,x1,x2
	real Factor,Change,SumRVV,SumWt,SumRVM
	complex Temp
	real Factors(11)
	data Factors/0.5,0.75,8*0.9,0.5/
c
c  Calculate initial phase gain estimates.
c
	call phasol(nbl,nants,Sum,SumVM,b1,b2,gain,convrg)
	if(.not.convrg)return
c
c  Get an initial approximation of the gain solution. This finds a single
c  real gain which minimises the error. This helps stablise the algorithm
c  when the gain solution is very different from 1 (e.g. when we are
c  calculating a priori calibration factors).
c
	SumRVM = 0
	SumRVV = 0
	do i=1,nbl
	  SumRVM = SumRVM + conjg(gain(b1(i)))*gain(b2(i))*SumVM(i)
	  SumRVV = SumRVV + SumVV(i)
	enddo
	Factor = sqrt(abs(SumRVM / SumRVV))
c
c  Ready for the amplitude/phase solution.
c
	do i=1,nants
	  Gain(i) = Factor * Gain(i)
	  Sum(i) = 0.
	  Sum2(i) = 0.
	  Sum3(i) = 0.
	enddo
c
c  Iterate.
c
	Convrg = .false.
	Niter = 0
	do while(.not.Convrg.and.Niter.lt.MaxIter)
	  Niter = Niter + 1
c
c  Set the damping constant. I do not think this is really necessary.
c  AIPS does it.
c
	  if(nants.le.6)then
	    Factor = 0.5
	  else
	    Factor = Factors(min(11,Niter))
	  endif
c
c  Sum the contributions over the baselines.
c
	  do i=1,nbl
	    Sum(b1(i)) = Sum(b1(i)) + Gain(b2(i)) *	  SumVM(i)
	    Sum(b2(i)) = Sum(b2(i)) + Gain(b1(i)) * conjg(SumVM(i))
	    Sum2(b1(i)) = Sum2(b1(i)) +
     *	     (real(Gain(b2(i)))**2 + aimag(Gain(b2(i)))**2) * SumVV(i)
	    Sum2(b2(i)) = Sum2(b2(i)) +
     *	     (real(Gain(b1(i)))**2 + aimag(Gain(b1(i)))**2) * SumVV(i)
	  enddo
c
c  Sum the contribution from the redundant baselines.
c
	  do i=1,nreds
	    Sum(rb1(i)) = Sum(rb1(i)) +
     *		Gain(rb2(i))*Gain(rb3(i))*conjg(Gain(rb4(i))*CV(i))
	    Sum2(rb1(i)) = Sum2(rb1(i)) + 
     *	     (real(Gain(rb2(i)))**2 + aimag(Gain(rb2(i)))**2)*SumVV(i)
	    if(rb2(i).eq.rb3(i))then
	      Sum2(rb2(i)) = Sum2(rb2(i)) + 
     *	     (real(Gain(rb1(i)))**2 + aimag(Gain(rb1(i)))**2)*SumVV(i) +
     *	     (real(Gain(rb4(i)))**2 + aimag(Gain(rb4(i)))**2)*SumVV(i)
	      Sum3(rb2(i)) = Sum3(rb2(i)) -
     *				2*conjg(Gain(rb1(i))*Gain(rb4(i))*CV(i))
	    else
	      Sum(rb2(i)) = Sum(rb2(i)) + 
     *		Gain(rb1(i))*conjg(Gain(rb3(i)))*Gain(rb4(i))*CV(i)
	      Sum2(rb2(i)) = Sum2(rb2(i)) + 
     *	       (real(Gain(rb1(i)))**2 + aimag(Gain(rb1(i)))**2)*SumVV(i)
	      Sum(rb3(i)) = Sum(rb3(i)) + 
     *		Gain(rb1(i))*conjg(Gain(rb2(i)))*Gain(rb4(i))*CV(i)
	      Sum2(rb3(i)) = Sum2(rb3(i)) + 
     *	       (real(Gain(rb4(i)))**2 + aimag(Gain(rb4(i)))**2)*SumVV(i)
	    endif
	    Sum(rb4(i)) = Sum(rb4(i)) +
     *	      conjg(Gain(rb1(i)))*Gain(rb2(i))*Gain(rb3(i))*conjg(CV(i))
	    Sum2(rb4(i)) = Sum2(rb4(i)) + 
     *	     (real(Gain(rb3(i)))**2 + aimag(Gain(rb3(i)))**2)*SumVV(i)
	  enddo
c
c  Update the gains.
c
	  Change = 0
	  SumWt = 0
c#maxloop 32
	  do i=1,nants
	    a11 = Sum2(i) + real(Sum3(i))
	    a12 = aimag(Sum3(i))
	    a21 = a12
	    a22 = Sum2(i) - real(Sum3(i))
	    det = a11*a22 - a12*a21
	    x1 = ( a22*real(Sum(i)) - a12*aimag(Sum(i)) ) / det
	    x2 = (-a21*real(Sum(i)) + a11*aimag(Sum(i)) ) / det
	    Temp = cmplx(x1,x2) - Gain(i)
	    Gain(i) = Gain(i) + Factor * Temp
	    Change = Change + (real(Temp)**2 + aimag(Temp)**2)
	    SumWt  = SumWt  + (real(Gain(i))**2 + aimag(Gain(i))**2)
	    Sum(i)  = 0.
	    Sum2(i) = 0.
	    Sum3(i) = 0.
	  enddo
	  Convrg = Change/SumWt .lt. Epsi
	enddo
	Convrg = Change/SumWt .lt. Epsi2
	end
