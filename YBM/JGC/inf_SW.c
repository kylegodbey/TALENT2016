#include <iostream>	// cout cin
#include <math.h>	// sin
#include <vector>	// vectors
#include "inf_SW.h"

using namespace std;

// Iput variables
double     a = 35.;	// Box width  [fm]
double     l = 6.;	// Well width [fm]
double     h = 0.01;	// Mesh width [fm]
double wellD = 1000000;	// Well depth [keV]
double  eMin = 0.;	// Min limit  [keV]
double  eMax = 10.;	// Max limit  [keV]
double eStep = 0.0005;

double h22m_fac = 20.75;
double wfPrev, wfLast;

int main()
{
	double trialE = (eMax - eMin) / 2;
	vector<double> wf_val;

	for(int jj=0; jj<(eMax-eMin)/eStep; jj++){
		
		cout << eMin << "\r";
		wf_val.push_back(0);
		wf_val.push_back(0.5);



		for(int i=0; i<a/h; i++){
//			wf_val.push_back(numerovAlgorithm(0.1671, wf_val.at(i+1), wf_val.at(i)));
			wf_val.push_back(numerovAlgorithm(eMin, wf_val.at(i+1), wf_val.at(i)));
		}
		

		if(jj>0){
			wfLast = wf_val.at(-1+wf_val.size());
			if( wfPrev/wfLast < 0 ) cout << "BING!\t" << eMin-eStep << "\t" << eMin << "\t" << wfPrev << "\t" << wfLast << endl;


/*			if( abs( (wf_val.at(-1+wf_val.size())) < 0.01)){
				char filename[512];
				sprintf(filename,"output_%1.3f.dat",eMin);
				ofstream opFile;
				opFile.open(filename);
				for(int k=0; k<a/h; k++) opFile << k << "\t" << wf_val.at(k) << endl;
				opFile.close();
			}
*/		}

		wfPrev = wf_val.at(-1+wf_val.size());
		wf_val.clear();
		eMin += eStep;
	}
}

double numerovAlgorithm(double E, double f_x, double f_x_h)
{
	double a[3];
	double vx = E / h22m_fac;

	a[0] = 2. * (1. - 5./12. * vx * h * h);
	a[1] = 1. * (1. + 1./12. * vx * h * h);
	a[2] = 1. * (1. + 1./12. * vx * h * h);

	double nuWF = ((a[0] * f_x) - (a[1] * f_x_h)) / a[2];

	return nuWF;
}
